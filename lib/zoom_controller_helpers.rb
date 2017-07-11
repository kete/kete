module ZoomControllerHelpers
  unless included_modules.include? ZoomControllerHelpers
    # set up our helper methods
    def self.included(klass)
      # only intended to add helper methods in app/controllers/application.rb
      if klass.name == 'ApplicationController'
        klass.helper_method :zoom_class_controller, :zoom_class_from_controller, :zoom_class_humanize,
                            :zoom_class_plural_humanize, :zoom_class_humanize_after, :zoom_class_params_key_from_controller
      end
    end

    # * makes sure comments are deleted before an item is
    def zoom_item_destroy(item)
      successful = true
      item.comments.each do |comment|
        successful = comment.destroy
        if !successful
          return successful
        end
      end

      if successful
        successful = item.destroy
      end
    end

    # this has very little to do with explicit zoom_destroy anymore
    # but we're not bothering to rename it at the moment
    # the main thing is that it cause related items zoom records to be rebuilt
    # the zoom_item_destroy makes sure comments are deleted as expected
    def zoom_destroy_and_redirect(zoom_class, pretty_zoom_class = nil)
      if pretty_zoom_class.nil?
        pretty_zoom_class = zoom_class
      end
      begin
        item = Module.class_eval(zoom_class).find(params[:id])

        related_items = item.related_items

        @successful = zoom_item_destroy(item)
      rescue
        flash[:error], @successful  = $!.to_s, false
      end

      if @successful
        # TODO: should be moved to backgroundrb worker
        related_items.each do |related_item|
          related_item.prepare_and_save_to_zoom
        end

        flash[:notice] = I18n.t('zoom_controller_helpers_lib.zoom_destroy_and_redirect.destroyed',
                                pretty_zoom_class: pretty_zoom_class)
      end
      redirect_to action: 'list'
    end

    # called by either before filter on destroy
    # or after filter on update
    def update_zoom_record_for_related_items
      if CACHES_CONTROLLERS.include?(params[:controller]) && params[:controller] != 'baskets'
        item = item_from_controller_and_id(false)

        # Walter McGinnis, 2009-05-11
        # this doesn't work because of multiple render calls
        # postponing until some time later
        # at that time, it should only be called
        # if item moved to a new basket
        # should be moved to backgroundrb worker
        # item.related_items.each do |related_item|
        #   prepare_and_save_to_zoom(related_item)
        # end
      end
    end

    def zoom_class_controller(zoom_class)
      zoom_class_controller = String.new
      case zoom_class
      when 'StillImage'
        zoom_class_controller = 'images'
      when 'Video'
        zoom_class_controller = 'video'
      when 'Comment'
        zoom_class_controller = 'comments'
      when 'AudioRecording'
        zoom_class_controller = 'audio'
      else
        zoom_class_controller = zoom_class.tableize
      end
    end

    def zoom_class_from_controller(controller)
      zoom_class = String.new
      case controller
      when 'images'
        zoom_class = 'StillImage'
      when 'video'
        zoom_class = 'Video'
      when 'comments'
        zoom_class = 'Comment'
      when 'audio'
        zoom_class = 'AudioRecording'
      else
        zoom_class = controller.classify
      end
    end

    def zoom_class_humanize(zoom_class)
      return I18n.t("zoom_controller_helpers_lib.zoom_class_humanize.#{zoom_class.underscore}")
    end

    def zoom_class_params_key_from_controller(controller)
      zoom_class_from_controller(controller).tableize.singularize.to_sym
    end

    def zoom_class_plural_humanize(zoom_class)
      return I18n.t("zoom_controller_helpers_lib.zoom_class_plural_humanize.#{zoom_class.underscore}")
    end

    def zoom_class_humanize_after(count, zoom_class)
      humanized = count.to_s + ' '
      if count.to_i != 1
        humanized += zoom_class_plural_humanize(zoom_class)
      else
        humanized += zoom_class_humanize(zoom_class)
      end
      humanized
    end

    include GenericMutedWorkerCallingHelpers

    # a method for use by generic_muted_worker
    # to do zoom rebuilds via backgroundrb
    # unless in test environement
    # meant to be used in place of direct item.prepare_and_save_to_zoom
    # as that is synchronous and can hold up request responses significantly for items that have large zoom records
    # this moves the prepare_and_save_to_zoom process to asynchronous backgroundrb process
    def update_search_record_for(item, options = { })
      # ROB: we don't use zoom and this was causing errors so removed.
    end

    def worker_zoom_for(options)
      if options[:zoom_items].blank? || options[:zoom_items].size < 1
        Rails.logger.info('Error in worker_zoom_for call, item not specified. Passed in options are: ' + options.inspect)
        raise ArguementError
      end

      options[:zoom_items].each do |item_pair|
        item_pair.keys.first.constantize.find(item_pair.values.first).prepare_and_save_to_zoom
      end
    end

    protected

    # Evaluate a possibly unsafe string into a zoom class.
    # I.e.  "StillImage" => StillImage
    def only_valid_zoom_class(param)
      if ZOOM_CLASSES.member?(param)
        param.constantize
      else
        raise(ArgumentError, "Zoom class name expected. #{param} is not registered in ZOOM_CLASSES.")
      end
    end
  end
end
