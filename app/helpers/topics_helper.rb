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

  def oai_dc_xml_dc_topic_content(xml,topic)
    # work through content, see what should be it's own dc element
    # and what should go in a group dc:description
    temp_content = topic.content
    content_hash = XmlSimple.xml_in("<dummy>#{temp_content}</dummy>", 'contentkey' => 'value', 'forcearray'   => false)

    non_dc_content_hash = Hash.new
    re = Regexp.new("^dc")
    content_hash.keys.each do |field|
      if !content_hash[field]['xml_element_name'].blank? && re.match(content_hash[field]['xml_element_name'])
        # it's a dublin core tag, just spit it out
        xml.tag!(content_hash[field]['xml_element_name'], content_hash[field]['value'])
      elsif !content_hash[field]['xml_element_name'].blank?
        # use xml_element_name, but append to non_dc_content
        x = Builder::XmlMarkup.new
        non_dc_content += x.tag!(content_hash[field]['xml_element_name'], content_hash[field]['value'])
      else
        non_dc_content_hash[field] = content_hash[field]['value']
      end
    end

    if !non_dc_content_hash.blank?
      xml.tag!("dc:description") do
        non_dc_content_hash.each do |key, value|
          xml.tag!(key, value)
        end
      end
    end
  end
end
