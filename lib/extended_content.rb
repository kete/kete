require "rexml/document"

# not much here for now, but could expand later
module ExtendedContent
  include REXML

  # simply pulls xml attributes in extended_content column out into a hash
  def xml_attributes
    # we use rexml for better handling of the order of the hash
    extended_content = Document.new("<dummy_root>#{self.extended_content}</dummy_root>")

    temp_hash = Hash.new
    root = extended_content.root
    position = 1
    root.elements.each do |field|
      temp_hash[position.to_s] = Hash.from_xml(field.to_s)
      position += 1
    end

    return temp_hash
  end

  def xml_attributes_without_position
    # we use rexml for better handling of the order of the hash
    extended_content_hash = Hash.from_xml("<dummy_root>#{self.extended_content}</dummy_root>")
    return extended_content_hash["dummy_root"]
  end
end
