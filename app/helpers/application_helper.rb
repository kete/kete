# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def zoom_class_humanize(zoom_class)
    humanized = String.new
    case zoom_class
      when "AudioRecording"
      humanized = 'Audio'
      when "WebLink"
      humanized = 'Web Link'
      when "StillImage"
      humanized = 'Image'
      else
      humanized = zoom_class.humanize
    end
    return humanized
  end

  def zoom_class_plural_humanize(zoom_class)
    plural_humanized = String.new
    case zoom_class
      when "AudioRecording"
      plural_humanized = 'Audio'
      when "WebLink"
      plural_humanized = 'Web Links'
      when "StillImage"
      plural_humanized = 'Images'
      else
      plural_humanized = zoom_class.humanize.pluralize
    end
    return plural_humanized
  end

  def zoom_class_controller(zoom_class)
    zoom_class_controller = String.new
    case zoom_class
      when "StillImage"
      zoom_class_controller = 'images'
      when "Video"
      zoom_class_controller = 'video'
      when "AudioRecording"
      zoom_class_controller = 'audio'
      else
      zoom_class_controller = zoom_class.tableize
    end
    return zoom_class_controller
  end

end
