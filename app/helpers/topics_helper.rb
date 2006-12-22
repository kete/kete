module TopicsHelper
  def display_xml_attributes(topic)
    html_string = ""
    # TODO: these should have their order match the specified order for the topic_type
    topic.xml_attributes.each do |field_key, field_value|
      field_name = field_key.humanize
      html_string += "<p> #{field_name}: #{field_value} </p>\n"
    end
    return html_string
  end
end
