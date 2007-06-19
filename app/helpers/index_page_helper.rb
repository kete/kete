module IndexPageHelper
  # grabbed from http://www.juixe.com/techknow/index.php/2006/07/15/acts-as-taggable-tag-cloud/
  # and modified to suit our tags hash
  def tag_cloud(tags, classes)
    max, min = 0, 0
    tags.each { |t|
      t_count = t[:taggings_count].to_i
      max = t_count if t_count > max
      min = t_count if t_count < min
    }

    divisor = ((max - min) / classes.size) + 1

    tags.each { |t|
      t_count = t[:taggings_count].to_i
      yield t[:id], t[:name], classes[(t_count - min) / divisor]
    }
  end

  def link_to_tagged_in_basket(options = {})
    link_to h(options[:name]),
    { :controller => 'search', :action => 'all',
      :tag => options[:id],
      :trailing_slash => true,
      :controller_name_for_zoom_class => zoom_class_controller(options[:zoom_class])},
    :class => options[:css_class]
  end
end
