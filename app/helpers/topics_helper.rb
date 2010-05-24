module TopicsHelper
  def topic_types_counts_for(topic)
    html = "<ul>"
    topic_types_and_counts = topic.related_topics.collection_of_objects_and_counts_for(:topic_type, true)
    topic_types_and_counts.each do |topic_type, count|
      title = "#{h(topic_type.name.pluralize)} (#{count})"
      html += "<li>" + link_to_related_items_of(topic, 'Topic', { :link_text => title },
                                                { :topic_type => topic_type.urlified_name }) + "</li>"
    end
    html += "</ul>"
    html
  end
end
