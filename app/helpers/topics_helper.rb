module TopicsHelper
  include AjaxScaffold::Helper

  def num_columns
    scaffold_columns.length + 1
  end

  def scaffold_columns
    Topic.scaffold_columns
  end
  # above ajaxscaffold generated helpers, now for ours

  def display_xml_attributes(topic)
    html_string = ""
    topic.xml_attributes.each do |field_key, field_value|
      field_name = field_key.humanize
      html_string += "<p> #{field_name}: #{field_value} </p>\n"
    end
    return html_string
  end
end
