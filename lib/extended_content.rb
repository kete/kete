# Requirements for XML conversion of extended fields
require "rexml/document"
require 'builder'
require 'xmlsimple'


# not much here for now, but could expand later
module ExtendedContent
  CLASSES_WITH_SUMMARIES = ['Topic', 'Document']

  unless included_modules.include? ExtendedContent
    
    include ExtendedContentHelpers
    
    def xml(force_new = false)
      if force_new
        @builder_xml = Builder::XmlMarkup.new
      else
        @builder_xml ||= Builder::XmlMarkup.new
      end
    end
    
    def extended_content_xml
      read_attribute(:extended_content)
    end

    def extended_content_xml=(xml_string)
      write_attribute(:extended_content, xml_string)
    end

    def extended_content
      convert_xml_to_extended_fields_hash
    end
    
    def extended_content_pairs
      convert_xml_to_key_value_hash
    end
    
    def extended_content=(content_as_array)
      # Do the behind the scenes stuff..
      self.extended_content_xml = convert_extended_content_to_xml(content_as_array)
    end

    # simply pulls xml attributes in extended_content column out into a hash
    def xml_attributes
      # we use rexml for better handling of the order of the hash
      extended_content = REXML::Document.new("<dummy_root>#{self.extended_content_xml}</dummy_root>")

      temp_hash = Hash.new
      root = extended_content.root
      position = 1

      form_fields = all_field_mappings

      if form_fields.size > 0
        form_fields.each do |extended_field_mapping|
          f_id = extended_field_mapping.extended_field_label.downcase.gsub(/\s/, '_')
          f_multiple = "#{f_id}_multiple"
          field_xml = root.elements[f_multiple]
          # if we didn't match a multiple
          # then we are all clear to use the plain f_id
          if field_xml.blank?
            field_xml = root.elements[f_id]
          end
          if !field_xml.blank?
            temp_hash[position.to_s] = Hash.from_xml(field_xml.to_s)
            position += 1
          end
        end
      end

      return temp_hash
    end

    def xml_attributes_without_position
      # we use rexml for better handling of the order of the hash
      
      XmlSimple.xml_in("<dummy>#{extended_content_xml}</dummy>", "contentkey" => "value", "forcearray" => false)
      
      # OLD METHOD
      # extended_content_hash = Hash.from_xml("<dummy_root>#{self.extended_content_xml}</dummy_root>")
      # return extended_content_hash["dummy_root"]
    end

    def can_have_short_summary?
      CLASSES_WITH_SUMMARIES.include?(self.class.name)
    end
    
    private

      def convert_extended_content_to_xml(params_hash)
        
        # Force a new instance of Bulder::XMLMarkup to be spawned
        xml(true)
        
        all_field_mappings.collect do |field_to_xml|

          # label is unique, whereas xml_element_name is not
          # thus we use label for our internal (topic.extended_content) storage of arbitrary attributes
          # xml_element_name is used for exported topics, such as oai/dc records
          field_name = field_to_xml.extended_field_label.downcase.gsub(/\s/, '_')
          
          # because we piggyback multiple, it doesn't have a ? method
          # even though it is boolean
          if field_to_xml.extended_field_multiple

            # we have multiple values for this field in the form
            # collect them in an outer tag
            # do an explicit key, so we end up with a hash
            xml.tag!("#{field_name}_multiple") do
              hash_of_values = params_hash[field_name]
              
              # Do not store empty values
              hash_of_values = hash_of_values.reject { |k, v| v.blank? }
              
              if !hash_of_values.blank?
                hash_of_values.keys.sort.each do |key|
                  xml.tag!(key) do
                    extended_content_field_xml_tag(
                      :xml => xml,
                      :field => field_name,
                      :value => params_hash[field_name][key],
                      :xml_element_name => field_to_xml.extended_field_xml_element_name,
                      :xsi_type => field_to_xml.extended_field_xsi_type
                    )
                  end
                end
              else
                # this handles the case where edit has changed the item from one topic type to a sub topic type
                # and there isn't an existing value for this multiple
                # generates empty xml elements for the field
                key = 1.to_s
                xml.tag!(key) do
                    extended_content_field_xml_tag(
                      :xml => xml,
                      :field => field_name,
                      :value => '',
                      :xml_element_name => field_to_xml.extended_field_xml_element_name,
                      :xsi_type => field_to_xml.extended_field_xsi_type
                    )
                end
              end
            end
          else
            extended_content_field_xml_tag(
              :xml => xml,
              :field => field_name,
              :value => params_hash[field_name],
              :xml_element_name => field_to_xml.extended_field_xml_element_name,
              :xsi_type => field_to_xml.extended_field_xsi_type
            )
          end
          
        # TODO: For some reason a bunch of duplicate extended fields are created. Work out why.
        end.flatten.uniq.join("\n")
      end

      def convert_xml_to_extended_fields_hash
        xml_attributes_without_position
      end
      
      def convert_xml_to_key_value_hash
        options = {
          "contentkey"  => "value", 
          "forcearray"  => false,
          "noattr"      => true
        }
        
        XmlSimple.xml_in("<dummy>#{extended_content_xml}</dummy>", options).collect { |k, v| [k, v.empty? ? nil : v] }
      end
      
      # All available extended field mappings for the given item.
      # Overloaded in Topic model (special case with hierarchical TopicTypes)
      def all_field_mappings
        ContentType.find_by_class_name(self.class.name).content_type_to_field_mappings
      end
    
  end
end
