# frozen_string_literal: true

module TopicsHelper
  def topic_type_breadcrumb_for(topic)
    html = '<ul class="breadcrumb">'
    count = 0
    topic_types = topic.topic_type.self_and_ancestors
    topic_types.each do |tt|
      count += 1
      html += '<li class="'

      classes = []
      classes << 'first' if count == 1

      if topic_types.size == count
        classes << 'selected-topic-type'
      else
        classes << 'ancestor-topic-type'
      end

      html += classes.join(' ') + '">'

      unless count == 1
        html += '<span class="breadcrumb-delimiter">'
        html += t('base.breadcrumb_delimiter')
        html += '</span>'
      end
      html += link_to(h(tt.name), url_for_topics_of_type(tt))
    end
    html += '</ul>'
  end
end

# add first class to first item
# add ancestor class to any item besides last
