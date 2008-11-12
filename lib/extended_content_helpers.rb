module ExtendedContentHelpers
  unless included_modules.include? ExtendedContentHelpers

    # OLDER METHODS
    # def non_dc_extended_content_field_xml(extended_content_hash,non_dc_extended_content_hash,field)
    #   # use xml_element_name, but append to non_dc_extended_content
    #   if !extended_content_hash[field]['xml_element_name'].blank?
    #     x = Builder::XmlMarkup.new
    #     if !extended_content_hash[field]['xml_element_name']['xsi_type'].blank?
    #       non_dc_extended_content += x.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'], "xsi:type".to_sym => extended_content_hash[field]['xml_element_name']['xsi_type'])
    #     else
    #       non_dc_extended_content += x.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'])
    #     end
    #   else
    #     non_dc_extended_content_hash[field] = extended_content_hash[field]
    #   end
    # end
    # 
    # def extended_content_hash_field_xml(xml,extended_content_hash,non_dc_extended_content_hash,field,re)
    #   if !extended_content_hash[field]['value'].blank? || !extended_content_hash[field].blank?
    #     if !extended_content_hash[field]['xml_element_name'].blank? && re.match(extended_content_hash[field]['xml_element_name'])
    #       # it's a dublin core tag, just spit it out
    #       # we allow for xsi:type specification
    #       if !extended_content_hash[field]['xml_element_name']['xsi_type'].blank?
    #         xml.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'], "xsi:type".to_sym => extended_content_hash[field]['xml_element_name']['xsi_type'])
    #       else
    #         xml.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'])
    #       end
    #     else
    #       non_dc_extended_content_field_xml(extended_content_hash,non_dc_extended_content_hash,field)
    #     end
    #   end
    # end

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
        # In the most simple case, the content is represented as "key" => "value", so use this directly now if it's available.
        @anonymous_fields << [original_field_key, data]
      elsif data.has_key?("value")

        # When xml_element_name is an attribute, the value is stored in a value key in a Hash.
        if data["xml_element_name"].blank?
          @anonymous_fields << [original_field_key, data["value"]]
        else
          @builder_instance.tag!(data["xml_element_name"], data["value"])
        end
      else 
        
        # This means we're dealing with a second set of nested values, to build these now.
        data_for_values = data.reject { |k, v| k == "xml_element_name" }.map { |k, v| v }

        if data["xml_element_name"].blank?
          @anonymous_fields << [original_field_key, ":#{data_for_values.join(":")}:"]
        else
          @builder_instance.tag!(data["xml_element_name"], ":#{data_for_values.join(":")}:")
        end
      end
      
    end
    
    def oai_dc_xml_for_field_name_and_value(name, value, options = {})
    end
    
    # OLD METHOD
    # def oai_dc_xml_dc_extended_content(xml,item)
    #   # work through extended_content, see what should be it's own dc element
    #   # and what should go in a group dc:description
    #   temp_extended_content = item.extended_content_xml
    #   if !temp_extended_content.blank? and temp_extended_content.starts_with?('<')
    #     extended_content_hash = XmlSimple.xml_in("<dummy>#{temp_extended_content}</dummy>", 'contentkey' => 'value', 'forcearray'   => false)
    #     
    #     non_dc_extended_content_hash = Hash.new
    #     re = Regexp.new("^dc")
    #     multi_re = Regexp.new("_multiple$")
    #     extended_content_hash.keys.each do |field|
    #       # condition that checks if this is a multiple field
    #       # if so move into it and does the following for each
    #       if multi_re.match(field)
    #         logger.debug("in multi")
    #         logger.debug("Working on field #{field.inspect}")
    #         # value is going to be a hash like this:
    #         # "1" => {field_name => value}, "2" => ...
    #         # we want the first field name followed by a :
    #         # and all values, separated by spaces (for now)
    #         hash_of_values = extended_content_hash[field]
    #         logger.debug("Hash of values is: #{hash_of_values.inspect}")
    #         hash_of_values.each_pair do |key, value|
    #           logger.debug("Working on key #{key.inspect} => #{value.inspect}")
    #           hash_of_values[key].each_pair do |subfield, subfield_value|
    #             logger.debug("Working on subfield #{subfield.inspect} => #{subfield_value.inspect}")
    #             extended_content_hash_field_xml(xml,hash_of_values[key],non_dc_extended_content_hash,subfield,re)
    #           end
    #         end
    #       else
    #         extended_content_hash_field_xml(xml,extended_content_hash,non_dc_extended_content_hash,field,re)
    #       end
    #     end
    # 
    #     if !non_dc_extended_content_hash.blank?
    #       xml.tag!("dc:description") do
    #         non_dc_extended_content_hash.each do |key, value|
    # 
    #           if value.is_a?(Hash)
    #             xml.tag!(key, ":#{value.values.join(":")}:")
    #           else
    #             xml.tag!(key, value)
    #           end
    #           
    #         end
    #       end
    #     end
    #   end
    # end

    # extended_content_xml_helpers
    def extended_content_field_xml_tag(options = {})
      
      begin
        xml = options[:xml]
        field = options[:field]
        value = options[:value] || nil
        xml_element_name = options[:xml_element_name] || nil
        xsi_type = options[:xsi_type] || nil

        options = {}
        options.merge!(:xml_element_name => xml_element_name) unless xml_element_name.blank?
        options.merge!(:xsi_type => xsi_type) unless xsi_type.blank?
        
        if value.is_a?(Hash)
          xml.tag!(field, options) do |tag|
            value.each_pair do |k, v|
              tag.tag!(k, converted_choice_value(v)) unless v.to_s.blank?
            end
          end
        else
          xml.tag!(field, value, options)
        end
          
      rescue
        logger.error("failed to format xml: #{$!.to_s}")
      end
    end
        
    def converted_choice_value(value)
      choice = Choice.find_by_value(value) || Choice.find_by_label(value)
      choice ? choice.value : ""
    end
    
    
  end
end
