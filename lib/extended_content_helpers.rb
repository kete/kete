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
          nested.tag!(k, encode_ampersands(v))
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
          @builder_instance.tag!(data["xml_element_name"], encode_ampersands(data["value"]))
        end
      else 
        
        # This means we're dealing with a second set of nested values, to build these now.
        data_for_values = data.reject { |k, v| k == "xml_element_name" }.map { |k, v| v }
        
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

        options = {}
        options.merge!(:xml_element_name => xml_element_name) unless xml_element_name.blank?
        options.merge!(:xsi_type => xsi_type) unless xsi_type.blank?
        
        if value.is_a?(Hash)
          xml.tag!(field, options) do |tag|
            value.each_pair do |k, v|
              next if v.to_s.blank?
              
              # Handle the creation of new choices where the choice is not recognised.
              if converted_choice_value(v).blank? && %w(choice autocomplete).member?(extended_field.ftype) && extended_field.user_choice_addition?
                index = value.to_a.index([k, v])
                parent = index >= 1 ? choice_from_value(value.to_a.at(index - 1).last) : Choice.find(1)
                
                begin
                  choice = Choice.create!(:label => v)
                  choice.move_to_child_of(parent)
                  choice.save!
                  extended_field.choices << choice
                  extended_field.save!
                  
                  tag.tag!(k, choice.value)
                rescue
                  next
                end
              
              # Handle the normal case  
              else
                tag.tag!(k, converted_choice_value(v).blank? ? v : converted_choice_value(v))
              end
              
            end
          end
        else
          xml.tag!(field, value, options)
        end
          
      rescue
        logger.error("failed to format xml: #{$!.to_s}")
      end
    end
    
    def choice_from_value(value)
      Choice.find_by_value(value) || nil
    end
        
    def converted_choice_value(value)
      choice = choice_from_value(value)
      choice ? choice.value : ""
    end
    
    def encode_ampersands(value)
      value.gsub("&", "&amp;")
    end
    
    
  end
end
