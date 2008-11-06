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
    
      def converted_value(value, signal_from_params_hash = nil, options = {})
        if signal_from_params_hash == "true"
          
          # When we're receiving values from choice field autocomplete type editors, we get sent the label always.
          # So, we need to swap the label for the value of the label.
          Choice.find_by_label(value).value rescue value
        else
          
          # Otherwise, we get sent the value from the HTML SELECT, so we can proceed as normal
          value
        end
      end

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
              hash_of_values = hash_of_values ? hash_of_values.reject { |k, v| v.blank? } : nil
              
              if !hash_of_values.blank?
                hash_of_values.keys.sort.each do |key|
                  xml.tag!(key) do
                    extended_content_field_xml_tag(
                      :xml => xml,
                      :field => field_name,
                      :value => converted_value(params_hash[field_name][key], params_hash[field_name][key + "_from_autocomplete"]),
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
              :value => converted_value(params_hash[field_name], params_hash[field_name + "_from_autocomplete"]),
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
        
        XmlSimple.xml_in("<dummy>#{extended_content_xml}</dummy>", options).map do |key, value|
          if value.is_a?(Hash) && !value.empty?
            [key, value.values.map { |h| h.values }.flatten]
          else
            [key, value.empty? ? nil : value]
          end
        end
      end
      
      # All available extended field mappings for the given item.
      # Overloaded in Topic model (special case with hierarchical TopicTypes)
      def all_field_mappings
        ContentType.find_by_class_name(self.class.name).content_type_to_field_mappings
      end
      
      # Validation methods..
      def validate
        all_field_mappings.each do |mapping|
          
          field = mapping.extended_field
          
          if field.multiple?
            value_pairs = extended_content_pairs.select { |k, v| k == field.label.downcase.gsub(/\s/, '_') + "_multiple" }
            values = value_pairs.map { |k, v| v }
            validate_extended_content_multiple_values(mapping, values)
          else
            value_pairs = extended_content_pairs.select { |k, v| k == field.label.downcase.gsub(/\s/, '_') }
            values = value_pairs.map { |k, v| v }
            validate_extended_content_single_value(mapping, values.to_s)
          end
        end
      end
      
      # Generic validation methods
      def validate_extended_content_single_value(extended_field_mapping, value)
        # Handle required fields here..
        if extended_field_mapping.required && value.blank? && \
          extended_field_mapping.extended_field.ftype != "checkbox"
          
          errors.add_to_base("#{extended_field_mapping.extended_field.label} cannot be blank")
        else
          
          # Otherwise delegate to specialized method..
          if message = send("validate_extended_#{extended_field_mapping.extended_field.ftype}_field_content".to_sym, \
            extended_field_mapping, value)
            
            errors.add_to_base("#{extended_field_mapping.extended_field_label} #{message}")
          end
          
        end
      end
      
      def validate_extended_content_multiple_values(extended_field_mapping, values)
        
        if extended_field_mapping.required && values.all? { |v| v.to_s.blank? } && \
          extended_field_mapping.extended_field.ftype != "checkbox"
          
          errors.add_to_base("#{extended_field_mapping.extended_field.label} must have at least one value")
        else
          
          # Delete to specialized method..
          error_array = values.map do |v|
            send("validate_extended_#{extended_field_mapping.extended_field.ftype}_field_content".to_sym, \
              extended_field_mapping, v.to_s)
          end
          
          error_array.compact.each do |e| 
            errors.add_to_base("#{extended_field_mapping.extended_field.label} #{e}")
          end
        end
      end
      
      # Specialized validation methods below..
      
      def validate_extended_checkbox_field_content(extended_field_mapping, value)
        return nil if value.empty?
        
        unless value =~ /^(Yes|No)$/
          "must be a valid checkbox value (Yes or No)"
        end
      end
    
      def validate_extended_radio_field_content(extended_field_mapping, value)

        # Unsure right now how to handle radio fields. A single radio field is not of any use in the context
        # of extended fields/content.
        nil
      end
    
      def validate_extended_date_field_content(extended_field_mapping, value)
        
        # Allow nil values. If this is required, the nil value will be caught earlier.
        return nil if value.empty?
        
        unless value =~ /^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/
          "must be in the standard date format (YYYY-MM-DD)"
        end
      end
    
      def validate_extended_text_field_content(extended_field_mapping, value)
        
        # We accept pretty much any value for text fields
        nil
      end
    
      def validate_extended_textarea_field_content(extended_field_mapping, value)
        
        # We accept pretty much any value for text fields
        nil
      end
    
      def validate_extended_choice_field_content(extended_field_mapping, value)
        
        # Allow nil values. If this is required, the nil value will be caught earlier.
        return nil if value.empty?
        
        unless extended_field_mapping.extended_field.choices.map { |c| c.value }.member?(value)
          "must be a valid choice"
        end
      end
    
  end
end
