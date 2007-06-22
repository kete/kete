require "rexml/document"

# not much here for now, but could expand later
module ExtendedContent
  unless included_modules.include? ExtendedContent
    # simply pulls xml attributes in extended_content column out into a hash
    def xml_attributes
      # we use rexml for better handling of the order of the hash
      extended_content = REXML::Document.new("<dummy_root>#{self.extended_content}</dummy_root>")

      temp_hash = Hash.new
      root = extended_content.root
      position = 1

      form_fields = Array.new
      if self.class.name == 'Topic'
        self.topic_type.self_and_ancestors.each do |topic_type|
          form_fields = form_fields + topic_type.topic_type_to_field_mappings
        end
      else
        form_fields = ContentType.find_by_class_name(self.class.name).content_type_to_field_mappings
      end

      if form_fields.size > 0
        form_fields.each do |extended_field_mapping|
          f_id = extended_field_mapping.extended_field_label.downcase.gsub(/ /, '_')
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
      extended_content_hash = Hash.from_xml("<dummy_root>#{self.extended_content}</dummy_root>")
      return extended_content_hash["dummy_root"]
    end
  end
end
