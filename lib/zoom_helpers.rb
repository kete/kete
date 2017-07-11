module ZoomHelpers
  unless included_modules.include? ZoomHelpers
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
        options << [I18n.t('zoom_helpers_lib.zoom_controllers_as_options.all', zoom_class: zoom_class_plural_humanize(zoom_class)), zoom_class_controller(zoom_class)]
      end
      return options
    end
  end
end
