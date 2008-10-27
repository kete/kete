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
end
