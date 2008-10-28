module ExtendedContentHelpers
  unless included_modules.include? ExtendedContentHelpers
    def non_dc_extended_content_field_xml(extended_content_hash,non_dc_extended_content_hash,field)
      # use xml_element_name, but append to non_dc_extended_content
      if !extended_content_hash[field]['xml_element_name'].blank?
        x = Builder::XmlMarkup.new
        if !extended_content_hash[field]['xml_element_name']['xsi_type'].blank?
          non_dc_extended_content += x.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'], "xsi:type".to_sym => extended_content_hash[field]['xml_element_name']['xsi_type'])
        else
          non_dc_extended_content += x.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'])
        end
      else
        non_dc_extended_content_hash[field] = extended_content_hash[field]
      end
    end

    def extended_content_hash_field_xml(xml,extended_content_hash,non_dc_extended_content_hash,field,re)
      if !extended_content_hash[field]['value'].blank? || !extended_content_hash[field].blank?
        if !extended_content_hash[field]['xml_element_name'].blank? && re.match(extended_content_hash[field]['xml_element_name'])
          # it's a dublin core tag, just spit it out
          # we allow for xsi:type specification
          if !extended_content_hash[field]['xml_element_name']['xsi_type'].blank?
            xml.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'], "xsi:type".to_sym => extended_content_hash[field]['xml_element_name']['xsi_type'])
          else
            xml.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'])
          end
        else
          non_dc_extended_content_field_xml(extended_content_hash,non_dc_extended_content_hash,field)
        end
      end
    end

    def oai_dc_xml_dc_extended_content(xml,item)
      # work through extended_content, see what should be it's own dc element
      # and what should go in a group dc:description
      temp_extended_content = item.extended_content_xml
      if !temp_extended_content.blank? and temp_extended_content.starts_with?('<')
        extended_content_hash = XmlSimple.xml_in("<dummy>#{temp_extended_content}</dummy>", 'contentkey' => 'value', 'forcearray'   => false)
        
        # TODO: Remove logging
        # raise "XML: #{temp_extended_content.size.to_s}, OUTPUT: #{extended_content_hash.size.to_s}"

        non_dc_extended_content_hash = Hash.new
        re = Regexp.new("^dc")
        multi_re = Regexp.new("_multiple$")
        extended_content_hash.keys.each do |field|
          # condition that checks if this is a multiple field
          # if so move into it and does the following for each
          if multi_re.match(field)
            logger.debug("in multi")
            # value is going to be a hash like this:
            # "1" => {field_name => value}, "2" => ...
            # we want the first field name followed by a :
            # and all values, separated by spaces (for now)
            hash_of_values = extended_content_hash[field]
            hash_of_values.keys.each do |key|
              hash_of_values[key].keys.each do |subfield|
                extended_content_hash_field_xml(xml,hash_of_values[key],non_dc_extended_content_hash,subfield,re)
              end
            end
          else
            extended_content_hash_field_xml(xml,extended_content_hash,non_dc_extended_content_hash,field,re)
          end
        end

        if !non_dc_extended_content_hash.blank?
          xml.tag!("dc:description") do
            non_dc_extended_content_hash.each do |key, value|
              xml.tag!(key, value)
            end
          end
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

        # if we don't have xml_element_name, go with simplest case
        if xml_element_name.blank?
          xml.tag!(field, value)
        else
          # next simplest case, we have xml_element_name, but no xsi_type
          if xsi_type.blank?
            xml.tag!(field, value, :xml_element_name => xml_element_name )
          else
            xml.tag!(field, value, :xml_element_name => xml_element_name, :xsi_type => xsi_type)
          end
        end
      rescue
        logger.error("failed to format xml: #{$!.to_s}")
      end
    end
  end
end
