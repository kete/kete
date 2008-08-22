module ZoomControllerHelpers
  unless included_modules.include? ZoomControllerHelpers
    # set up our helper methods
    def self.included(klass)
      if klass.name.scan("Worker").blank?
        klass.helper_method :zoom_class_controller, :zoom_class_from_controller, :zoom_class_humanize, :zoom_class_plural_humanize
      end
    end

    # this keeps the RoR item around, just destroys zoom record
    # doesn't delete zoom records for any relations
    # mainly for cleaning out old zoom record
    # before we generate a new one
    def zoom_destroy_for(item)
      prepare_zoom(item)
      @successful = item.zoom_destroy
    end

    # destroy zoom and then item itself
    def zoom_item_destroy(item)
      @successful = true
      # delete any comments this is on
      item.comments.each do |comment|
        prepare_zoom(comment)
        @successful = comment.destroy
        if !@successful
          return @successful
        end
      end

      if @successful
        prepare_zoom(item)
        @successful = item.destroy
      end
    end

    def zoom_destroy_and_redirect(zoom_class,pretty_zoom_class = nil)
      if pretty_zoom_class.nil?
        pretty_zoom_class = zoom_class
      end
      begin
        item = Module.class_eval(zoom_class).find(params[:id])

        @successful = zoom_item_destroy(item)
      rescue
        flash[:error], @successful  = $!.to_s, false
      end

      if @successful
        flash[:notice] = "#{pretty_zoom_class} was successfully deleted."
      end
      redirect_to :action => 'list'
    end

    def zoom_class_controller(zoom_class)
      zoom_class_controller = String.new
      case zoom_class
      when "StillImage"
        zoom_class_controller = 'images'
      when "Video"
        zoom_class_controller = 'video'
      when "Comment"
        zoom_class_controller = 'comments'
      when "AudioRecording"
        zoom_class_controller = 'audio'
      else
        zoom_class_controller = zoom_class.tableize
      end
    end

    def zoom_class_from_controller(controller)
      zoom_class = String.new
      case controller
      when "images"
        zoom_class = 'StillImage'
      when "video"
        zoom_class = 'Video'
      when "comments"
        zoom_class = 'Comment'
      when "audio"
        zoom_class = 'AudioRecording'
      else
        zoom_class = controller.classify
      end
    end

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

    def prepare_zoom(item)
      # only do this for members of ZOOM_CLASSES
      if ZOOM_CLASSES.include?(item.class.name)
        begin
          item.oai_record = render_oai_record_xml(:item => item, :to_string => true)
          item.basket_urlified_name = item.basket.urlified_name
        rescue
          logger.error("prepare_and_save_to_zoom error: #{$!.to_s}")
        end
      end
    end

    def prepare_and_save_to_zoom(item)

      # This is always the public version..
      unless item.already_at_blank_version? || item.at_placeholder_public_version?
        prepare_zoom(item)
        item.zoom_save
      end

      # Redo the save for the private version
      if item.respond_to?(:private) and item.has_private_version? and !item.private?

        item.private_version do
          unless item.already_at_blank_version?
            prepare_zoom(item)
            item.zoom_save
          end
        end

        raise "Could not return to public version" if item.private?

      end
    end

    protected

    # Evaluate a possibly unsafe string into a zoom class.
    # I.e.  "StillImage" => StillImage
    def only_valid_zoom_class(param)
      if ZOOM_CLASSES.member?(param)
        Module.class_eval(param)
      else
        raise(ArgumentError, "Zoom class name expected. #{param} is not registered in ZOOM_CLASSES.")
      end
    end
  end
end
