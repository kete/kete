module IndexPageHelper
  def content_type_count_for(privacy, zoom_class)
    "#{number_with_delimiter(@items[privacy.to_sym]) || 0}"
  end
end
