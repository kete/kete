module IndexPageHelper
  def content_type_count_for(privacy, zoom_class)
    "#{number_with_delimiter(@basket_stats_hash["#{zoom_class}_#{privacy}"]) || 0}"
  end
end
