# frozen_string_literal: true

# class methods useful for defining scopes specific to an extended field
# requires that class being extended has been extended with ExtendedContentHelpers
module ExtendedContentScopeHelpers
  def field_condition_sql_for(pattern, field_id, exact_match = false)
    field = ExtendedField.find(field_id)
    xml = Nokogiri::XML::Builder.new

    pattern = "#{pattern}%" unless exact_match

    extended_content_field_xml_tag(
      xml: xml,
      field: field.label_for_params,
      value: pattern,
      xml_element_name: field.xml_element_name,
      xsi_type: field.xsi_type,
      extended_field: field
    )

    look_for_xml = xml.to_xml.lines.collect { |l| l.chomp }[1].downcase
    "LOWER(extended_content) LIKE '%#{look_for_xml}%'"
  end
end
