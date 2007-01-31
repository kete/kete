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
      # we now handle multiples
      multi_re = Regexp.new("_multiple$")
      if multi_re.match(field_key)
        # value is going to be a hash like this:
        # "1" => {field_name => value}, "2" => ...
        # we want the first field name followed by a :
        # and all values, separated by spaces (for now)
        field_name = String.new
        field_values = Array.new
        field_value.keys.each do |subfield_key|
          field_hash = topic.xml_attributes[field_key][subfield_key]
          field_hash.keys.each do |key|
            if field_name.blank?
              field_name = key.humanize
            end
            if !field_hash[key].blank? && !field_hash[key].to_s.match("xml_element_name")
              field_values << field_hash[key]
            end
          end
        end
        html_string += "<p> #{field_name}: #{field_values.to_sentence} </p>\n"
      else
        html_string += "<p> #{field_key.humanize}: "
        if !field_value.to_s.match("xml_element_name")
          html_string += field_value
        end
        html_string += " </p>\n"
      end
    end
    return html_string
  end
end
