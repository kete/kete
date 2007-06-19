module ZoomHelpers
  unless included_modules.include? ZoomHelpers
    def zoom_class_humanize(zoom_class)
      humanized = String.new
      case zoom_class
      when "AudioRecording"
        humanized = 'Audio'
      when "WebLink"
        humanized = 'Web Link'
      when "Comment"
        humanized = 'Discussion'
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
      when "Comment"
        plural_humanized = 'Discussion'
      when "StillImage"
        plural_humanized = 'Images'
      else
        plural_humanized = zoom_class.humanize.pluralize
      end
      return plural_humanized
    end

    # class methods for options for different attributes
    # optionally takes a additional_options array
    # which are added at the start
    def zoom_controllers_as_options(start_with_additional_options = nil)
      options = Array.new
      if !start_with_additional_options.nil?
        start_with_additional_options.each do |additional_option|
          options << [additional_option[0], additional_option[1]]
        end
      end
      ZOOM_CLASSES.each do |zoom_class|
        options << ["All " + zoom_class_plural_humanize(zoom_class), zoom_class_controller(zoom_class)]
      end
      return options
    end
  end
end
