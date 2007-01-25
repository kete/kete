module TopicsHelper
  def topic_type_select_with_indent(object, method, collection, value_method, text_method, current_value, html_options={ })
    result = "<select name='#{ object}[#{method}]'"
    html_options.each do |key, value|
        result << ' ' + key.to_s + '="' + value.to_s + '"'
    end
    result << ">\n"
    for element in collection
      indent_string = String.new
        element.level.times { indent_string += "&nbsp;" }
        if current_value == element.send(value_method)
          result << "<option value='#{ element.send(value_method)}' selected='selected'>#{indent_string}#{element.send(text_method)}</option>\n"
        else
          result << "<option value='#{element.send(value_method)}'>#{indent_string}#{element.send(text_method)}</option>\n"
        end
    end
    result << "</select>\n"
    return result
  end

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
