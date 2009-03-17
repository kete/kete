module ExtendedContentHelpers
  unless included_modules.include? ExtendedContentHelpers

    def oai_dc_xml_dc_extended_content(xml,item)
      @builder_instance = xml

      # We start with something like: {"text_field_multiple"=>{"2"=>{"text_field"=>{"xml_element_name"=>"dc:description", "value"=>"Value"}}, "3"=>{"text_field"=>{"xml_element_name"=>"dc:description", "value"=>"Second value"}}}, "married"=>"No", "check_boxes_multiple"=>{"1"=>{"check_boxes"=>"Yes"}}, "vehicle_type"=>{"1"=>"Car", "2"=>"Coupé"}, "truck_type_multiple"=>{"1"=>{"truck_type"=>{"1"=>"Lorry"}}, "2"=>{"truck_type"=>{"1"=>"Tractor Unit", "2"=>"Tractor with one trailer"}}}}

      @anonymous_fields = []

      item.xml_attributes_without_position.each_pair do |field_key, field_data|
        if field_key =~ /_multiple$/

          # We are dealing with multiple instances of an attribute
          field_data.each_pair do |index, data|
            oai_dc_xml_for_field_dataset(field_key, data.values.first)
          end

        else
          oai_dc_xml_for_field_dataset(field_key, field_data)
        end
      end

      # Build the anonymous fields that have no dc:* attributes.
      @builder_instance.tag!("dc:description") do |nested|
        @anonymous_fields.each do |k, v|
          nested.tag!(k, v)
        end
      end

    end

    def oai_dc_xml_for_field_dataset(field_key, data)
      original_field_key = field_key.gsub(/_multiple/, '')

      if data.is_a?(String)
        # This works as expected
        # In the most simple case, the content is represented as "key" => "value", so use this directly
        # now if it's available.
        @anonymous_fields << [original_field_key, data]
      elsif data.has_key?("value")

        # When xml_element_name is an attribute, the value is stored in a value key in a Hash.
        if data["xml_element_name"].blank?
          @anonymous_fields << [original_field_key, data["value"]]
        else
          @builder_instance.tag!(data["xml_element_name"], data["value"])
        end
      else

        # Example of what we might have in data at this point
        # {"xml_element_name"=>"dc:subject",
        #  "1"=>{"value"=>"Recreation", "label"=>"Sports & Recreation"},
        #  "2"=>"Festivals",
        #  "3"=>"New Year"}

        # This means we're dealing with a second set of nested values, to build these now.
        data_for_values = data.reject { |k, v| k == 'xml_element_name' || k == 'label' }.map { |k, v| v }

        # By this stage, we may have either of the following:
        # [{:label => 'Something', :value => 'This'}, {:label => 'Another', :value => 'That'}]
        # ['This', 'That']
        # (or a combination of both). So in this case, lets collect the correct values before continuing
        data_for_values.collect! { |v| (v.is_a?(Hash) && v['value']) ? v['value'] : v }.flatten.compact

        return nil if data_for_values.empty?

        if data["xml_element_name"].blank?
          @anonymous_fields << [original_field_key, ":#{data_for_values.join(":")}:"]
        else
          @builder_instance.tag!(data["xml_element_name"], ":#{data_for_values.join(":")}:")
        end
      end

    end

    # extended_content_xml_helpers
    def extended_content_field_xml_tag(options = {})

      begin
        xml = options[:xml]
        field = options[:field]
        value = options[:value] || nil
        xml_element_name = options[:xml_element_name] || nil
        xsi_type = options[:xsi_type] || nil
        extended_field = options[:extended_field] || nil

        # With choices from a dropdown, we can have preset dropdown and custom text field
        # So before we go any further, make sure we convert the values from Hash to either
        # the preset or custom value depending on which one is filled in
        if extended_field.ftype == 'choice'
          value.each do |key,choice_value|
            next unless choice_value.is_a?(Hash)
            choice = choice_value['preset'] # Preset values come from the dropdown
            choice = choice_value['custom'] unless choice_value['custom'].blank? # Custom values come from a text field
            value[key] = choice
          end
        end

        options = {}
        options.merge!(:xml_element_name => xml_element_name) unless xml_element_name.blank?
        options.merge!(:xsi_type => xsi_type) unless xsi_type.blank?

        if value.is_a?(Hash)
          xml.tag!(field, options) do |tag|
            value.each_pair do |k, v|
              next if v.to_s.blank?

              # splits a value into label and value
              # if it has a pattern of "label (value)"
              # useful for auto populated pseudo choices (all topic types available as choices)
              # where label may not be unique
              # and case where user may contribute a new choice
              parts = v.match(/(.+)\(([^\(\)]+)\)\Z/).to_a
              # l is label for this particular value
              l = nil
              unless parts.blank?
                l = parts[1].chomp(' ')
                v = parts[2]
              end

              # this will handle a number of cases, see comment in app/models/choice.rb
              # for details
              matching_choice = Choice.matching(l,v)

              # Handle the creation of new choices where the choice is not recognised.
              if !matching_choice && %w(autocomplete choice).include?(extended_field.ftype) && extended_field.user_choice_addition?
                sorted_values = value.dup.sort
                index = sorted_values.index([k, v])

                to_check = v
                if index && index >= 1
                  to_check = sorted_values.at(index - 1).last
                end

                parent = Choice.find_by_value(to_check) || Choice.find(1)

                begin
                  choice = Choice.create!(:value => v, :label => l)
                  choice.move_to_child_of(parent)
                  choice.save!
                  extended_field.choices << choice
                  extended_field.save!

                  if choice.value != choice.label
                    tag.tag!(k, choice.value, :label => choice.label)
                  else
                    tag.tag!(k, choice.value)
                  end
                rescue
                  next
                end

              # Handle the normal case
              else
                if matching_choice && matching_choice.value != matching_choice.label
                  tag.tag!(k, matching_choice.value, :label => matching_choice.label)
                else
                  # if there is a matching choice, use its value
                  # otherwise leave value to handled by validation
                  # will likely fail, but they will get error feedback and can modify
                  final_value = matching_choice ? matching_choice.value : v
                  tag.tag!(k, final_value)
                end
              end
            end
          end
        else
          # text and textarea, we intepret their values as not having
          # the special case where value and label are passed together
          unless %w(text textarea).include?(extended_field.ftype)
            # handle special case where we have a label embedded in the value
            # if our value looks like this
            # a label string (value)
            # then we reassign value to what is between the ()
            # and push the beginning string to a label attribute
            parts = Array.new
            # rescue incase value is something that can't have .match run on it (like integers/floats/fixnum etc)
            begin; parts = value.match(/(.+)\(([^\(\)]+)\)\Z/).to_a; rescue; end
            unless parts.blank?
              options.merge!(:label => parts[1].chomp(' '))
              value = parts[2]
            end
          end

          xml.tag!(field, value, options)
        end

      rescue
        logger.error("failed to format xml: #{$!.to_s}")
      end
    end

  end
end
