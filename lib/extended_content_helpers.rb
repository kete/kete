# -*- coding: utf-8 -*-
module ExtendedContentHelpers
  unless included_modules.include? ExtendedContentHelpers

    def oai_dc_xml_dc_extended_content(xml, item = self)
      @builder_instance = xml

      # We start with something like: {"text_field_multiple"=>{"2"=>{"text_field"=>{"xml_element_name"=>"dc:description", "value"=>"Value"}}, "3"=>{"text_field"=>{"xml_element_name"=>"dc:description", "value"=>"Second value"}}}, "married"=>"No", "check_boxes_multiple"=>{"1"=>{"check_boxes"=>"Yes"}}, "vehicle_type"=>{"1"=>"Car", "2"=>"Coupé"}, "truck_type_multiple"=>{"1"=>{"truck_type"=>{"1"=>"Lorry"}}, "2"=>{"truck_type"=>{"1"=>"Tractor Unit", "2"=>"Tractor with one trailer"}}}}

      @anonymous_fields = []

      fields_with_position = item.xml_attributes

      fields_in_sorted_array = fields_with_position.keys.sort_by { |s| s.to_s }.map { |key| fields_with_position[key] }
      fields_in_sorted_array.each do |field_hash|
          field_hash.each_pair do |field_key, field_data|
          # If this is google map contents, and no_map is '1', then do not use this data
          next if field_data.is_a?(Hash) && field_data['no_map'] && field_data['no_map'] == '1'
          
          if field_key =~ /_multiple$/
            # We are dealing with multiple instances of an attribute
            field_data.each_pair do |index, data|
              oai_dc_xml_for_field_dataset(field_key, data.values.first)
            end
          else
            oai_dc_xml_for_field_dataset(field_key, field_data)
          end
        end
      end

      # Build the anonymous fields that have no dc:* attributes.
      @builder_instance.send("dc:description") do |nested|
        @anonymous_fields.each do |k, v|
          nested.safe_send(k, v)
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
        # We add a dc:date for 5 years before and after the value specified
        # We also convert the single YYYY value to a format Zebra can search against
        # Note: We use DateTime instead of just Date/Time so that we can get dates before 1900
        if data.has_key?("circa")
          data['value'] = Time.zone.parse("#{data['value']}-01-01").xmlschema
          if data['circa'] == '1'
            five_years_before, five_years_after = (data['value'].to_i - 5), (data['value'].to_i + 5)
            @builder_instance.send("dc:date", Time.zone.parse("#{five_years_before}-01-01").xmlschema)
            @builder_instance.send("dc:date", Time.zone.parse("#{five_years_after}-12-31").xmlschema)
          end
        end

        # When xml_element_name is an attribute, the value is stored in a value key in a Hash.
        if data["xml_element_name"].blank?
          @anonymous_fields << [original_field_key, data["value"]]
        else
          # safe_send will drop the namespace from the element and therefore our dc elements
          # will not be parsed by zebra, only use safe_send on non-dc elements
          if data["xml_element_name"].include?("dc:")
            @builder_instance.send(data["xml_element_name"], data["value"])
          else
            @builder_instance.safe_send(data["xml_element_name"], data["value"])
          end
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
          @builder_instance.safe_send(data["xml_element_name"], ":#{data_for_values.join(":")}:")
        end
      end

    end

    # extended_content_xml_helpers
    # CAUTION: extended_field is not always passed in so do not call
    # extended_field.method because it will fail (example, lib/importer.rb)
    # Pass any extended field values you need through options
    def extended_content_field_xml_tag(options = {})

      begin
        xml = options[:xml]
        field = options[:field]
        value = options[:value] || nil
        xml_element_name = options[:xml_element_name] || nil
        xsi_type = options[:xsi_type] || nil
        extended_field = options[:extended_field] || nil
        if extended_field
          ftype = extended_field.ftype
          user_choice_addition = extended_field.user_choice_addition?
        else
          ftype = options[:ftype] || nil
          user_choice_addition = options[:user_choice_addition] || nil
        end

        # With choices from a dropdown, we can have preset dropdown and custom text field
        # So before we go any further, make sure we convert the values from Hash to either
        # the preset or custom value depending on which one is filled in
        if ftype == 'choice'
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
          xml.safe_send(field, options) do |tag|
            value.each_pair do |k, v|
              # convert to string so we don't get errors when running match later
              v = v.to_s

              next if v.blank?

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
              matching_choice_mapped = extended_field.choices.matching(l,v)

              # Handle the creation of new choices where the choice is not recognised.
              if !matching_choice_mapped && %w(autocomplete choice).include?(ftype) && user_choice_addition
                sorted_values = value.dup.sort
                index = sorted_values.index([k, v])

                to_check = v
                if index && index >= 1
                  to_check = sorted_values.at(index - 1).last
                end

                parent = Choice.find_by_value(to_check) || Choice.find(1)

                begin
                  if matching_choice
                    choice = matching_choice
                  else
                    choice = Choice.create!(:value => v, :label => l)
                    choice.move_to_child_of(parent)
                    choice.save!
                  end
                  extended_field.choices << choice
                  extended_field.save!

                  if choice.value != choice.label
                    tag.safe_send(k, choice.value, :label => choice.label)
                  else
                    tag.safe_send(k, choice.value)
                  end
                rescue
                  next
                end

              # Handle the normal case
              else
                if matching_choice && matching_choice.value != matching_choice.label
                  tag.safe_send(k, matching_choice.value, :label => matching_choice.label)
                else
                  # if there is a matching choice, use its value
                  # otherwise leave value to handled by validation
                  # will likely fail, but they will get error feedback and can modify
                  final_value = matching_choice ? matching_choice.value : v
                  tag.safe_send(k, final_value)
                end
              end
            end
          end
        else
          # text and textarea, we intepret their values as not having
          # the special case where value and label are passed together
          unless %w(text textarea).include?(ftype)
            # handle special case where we have a label embedded in the value
            # if our value looks like this
            # a label string (value)
            # then we reassign value to what is between the ()
            # and push the beginning string to a label attribute
            parts = Array.new

            # in case we are given something like this [ { 'value' => 'this', :label => 'that' } ]
            # This happens in the case of using replace_value_for method (field=) on a different field
            parts = if value.is_a?(Array) && value_label_hash?(value.first)
              [nil, value.first['label'], value.first['value']]
            elsif value.is_a?(String)
              value.match(/(.+)\(([^\(\)]+)\)\Z/).to_a
            else
              Array.new
            end

            unless parts.blank?
              options.merge!(:label => parts[1].chomp(' '))
              value = parts[2]
            end
          end

          xml.safe_send(field, value, options)
        end

      rescue
        logger.error("failed to format xml: #{$!.to_s}")
      end
    end

    def value_label_hash?(value)
      value.is_a?(Hash) && value.keys.include?('value') && value.keys.include?('label')
    end

  end
end
