module TopicsHelper
  def topic_types_counts_for(topic)
    html = "<ul>"
    topic_types_and_counts = topic.related_items.hash_of_topic_type_name_and_counts(true)
    topic_types_and_counts.each do |topic_type, count|
      title = "#{h(topic_type.name.pluralize)} (#{count})"
      html += "<li>" + link_to(title, url_for_topics_of_type(topic_type)) + "</li>"
    end
    html += "</ul>"
    html
  end
end
