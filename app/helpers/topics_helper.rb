module TopicsHelper
  def topic_types_counts_for(item)
    html = "<ul>"

    topic_types, related_topics = TopicType.all, item.child_related_topics
    topic_types.each do |topic_type|
      related_topics_of_this_topic_type = related_topics.select { |related| related.topic_type_id == topic_type.id }
      next if related_topics_of_this_topic_type.blank?
      title = "#{h(topic_type.name)} (#{related_topics_of_this_topic_type.size})"
      html += "<li>" + link_to(title, url_for_topics_of_type(topic_type)) + "</li>"
    end

    html += "</ul>"
    html
  end
end
