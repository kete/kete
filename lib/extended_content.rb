module ExtendedContent
  # not much here for now, but could expand later

  # simply pulls xml attributes in extended_content column out into a hash
  def xml_attributes
    temp_hash = Hash.from_xml("<dummy_root>#{self.extended_content}</dummy_root>")
    return temp_hash['dummy_root']
  end
end
