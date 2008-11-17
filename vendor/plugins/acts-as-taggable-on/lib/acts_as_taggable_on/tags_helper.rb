module TagsHelper
  # Kieran Pilkington, 2008-10-28
  # Comment out this entire section to prevent conflicts with our own tag_cloud method

  # See the README for an example using tag_cloud.
  #def tag_cloud(tags, classes)
  #  max_count = tags.sort_by(&:count).last.count.to_f
    
  #  tags.each do |tag|
  #    index = ((tag.count / max_count) * (classes.size - 1)).round
  #    yield tag, classes[index]
  #  end
  #end
end