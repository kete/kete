module TaggingController
  unless included_modules.include? TaggingController
    def self.included(klass)
      controller = klass.name.gsub("Controller", "")
      auto_complete_methods = Array.new
      # If we're in the Baskets controller, we have to make all zoom class tag completion methods on load
      if controller == 'Baskets'
        ZOOM_CLASSES.each do |zoom_class|
          item_key = zoom_class.underscore.downcase.to_sym
          klass.send :auto_complete_for, item_key, :tag_list, {}, { through: { object: 'tag', method: 'name' } }
          auto_complete_methods << "auto_complete_for_#{item_key}_tag_list".to_sym
        end
      else
        # the following code is basicly a copy of zoom_class_from_controller in ZoomControllerHelpers
        # find a way to get that method in here without all the errors is brings with it
        case controller
        when "Images"
          zoom_class = 'StillImage'
        when "Audio"
          zoom_class = 'AudioRecording'
        else
          zoom_class = controller.singularize
        end
        item_key = zoom_class.underscore.downcase.to_sym
        # klass.send :auto_complete_for, item_key, :tag_list, {}, { :through => { :object => 'tag', :method => 'name' } }
        auto_complete_methods << "auto_complete_for_#{item_key}_tag_list".to_sym
      end
      auto_complete_methods = ([ :add_tags ] + auto_complete_methods).flatten.compact
      klass.send :permit, "site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket", only: auto_complete_methods
    end

    # Kieran Pilkington, 2008/10/23
    # If we are updating via AJAX tag editor, then append the tags to the current tags list
    # then update the item, update zoom databases, and redirect/update the page on success
    # clearing of caches handled by application controller after_filter's
    def add_tags
      zoom_class = zoom_class_from_controller(params[:controller])
      item_key = zoom_class.underscore.to_sym

      @item = item_from_controller_and_id
      @item = public_or_private_version_of(@item)
      version_after_update = @item.max_version + 1

      if ZOOM_CLASSES.include?(zoom_class) && !params[item_key].blank? && !params[item_key][:tag_list].blank?
        params[item_key][:version_comment] = I18n.t('tagging_controller_lib.add_tags.version_comment',
                                                    tags_list: params[item_key][:tag_list])
        params[item_key][:tag_list] = "#{@item.tag_list.join(", ")}, #{params[item_key][:tag_list]}"
        params[item_key][:raw_tag_list] = params[item_key][:tag_list]

        @successful = @item.update_attributes(params[item_key])
        if @successful
          after_tags_added(starting_version: version_after_update - 1,
                           ending_version: version_after_update)

          @item = public_or_private_version_of(@item) # make sure we are back to private item if needed
          after_successful_zoom_item_update(@item, version_after_update)
          respond_to do |format|
            flash[:notice] = I18n.t('tagging_controller_lib.add_tags.tags_added', item_title: @item.title)
            format.html { redirect_to_show_for @item, private: (params[:private] == "true") }
          end
          return true
        else
          respond_to do |format|
            flash[:error] = I18n.t('tagging_controller_lib.add_tags.error_adding_tags',
                                   item_title: @item.title,
                                   errors: @item.errors['Tags'])
            format.html { redirect_to_show_for @item, private: (params[:private] == "true") }
          end
          return false
        end
      else
        @empty = true
        respond_to do |format|
          flash[:error] = I18n.t('tagging_controller_lib.add_tags.no_tags_entered', item_title: @item.title)
          format.html { redirect_to_show_for @item, private: (params[:private] == "true") }
        end
        return false
      end
    end

    # method that add-ons can define to do something after tags added
    def after_tags_added(options)
    end
  end
end
