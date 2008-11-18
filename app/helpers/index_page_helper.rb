module IndexPageHelper
  def content_type_count_for(privacy, zoom_class)
    "#{number_with_delimiter(@basket_stats_hash["#{zoom_class}_#{privacy}"]) || 0}"
  end

  def privacy_image_for(item)
    if item.is_private?
      image_tag 'privacy_icon.gif', :width => 16, :height => 15, :alt => "This item is private. ", :class => 'privacy_icon'
    end
  end
end
