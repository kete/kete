module TaggingController
  unless included_modules.include? TaggingController
    def self.included(klass)
      controller = klass.name.gsub("Controller", "").downcase
      # the following code is basicly a copy of zoom_class_from_controller in ZoomControllerHelpers
      # find a way to get that method in here without all the errors is brings with it
      case controller
      when "images"
        zoom_class = 'StillImage'
      when "audio"
        zoom_class = 'AudioRecording'
      else
        zoom_class = controller.singularize
      end
      item_key = zoom_class.underscore.to_sym
      klass.send :auto_complete_for, item_key, :tag_list, {}, { :through => { :object => 'tag', :method => 'name' } }
      klass.send :permit, "site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket", :only => [ :add_tags ]
    end

    # Kieran Pilkington, 2008/10/23
    # If we are updating via AJAX tag editor, then append the tags to the current tags list
    # then update the item, update zoom databases, and redirect/update the page on success
    # clearing of caches handled by application controller after_filter's
    def add_tags
      zoom_class = zoom_class_from_controller(params[:controller])
      item_key = zoom_class.underscore.to_sym

      if ZOOM_CLASSES.include?(zoom_class) && !params[item_key].blank? && !params[item_key][:tag_list].blank?
        @item = item_from_controller_and_id
        @item = public_or_private_version_of(@item)

        params[item_key][:version_comment] = "Only tags added: " + params[item_key][:tag_list]
        params[item_key][:tag_list] = "#{@item.tag_list.join(", ")}, #{params[item_key][:tag_list]}"
        params[item_key][:raw_tag_list] = params[item_key][:tag_list]

        @successful = @item.update_attributes(params[item_key])
        if @successful
          @item = public_or_private_version_of(@item) # make sure we are back to private item if needed
          after_successful_zoom_item_update(@item)
          respond_to do |format|
            flash[:notice] = "The new tag(s) have been added to #{@item.title}"
            format.html { redirect_to_show_for @item, :private => (params[:private] == "true") }
            format.js { render :file => File.join(RAILS_ROOT, 'app/views/topics/add_tags.js.rjs') }
          end
          return true
        else
          respond_to do |format|
            flash[:error] = "There was an error adding the new tags to #{@item.title}"
            format.html { redirect_to_show_for @item, :private => (params[:private] == "true") }
            format.js { render :file => File.join(RAILS_ROOT, 'app/views/topics/add_tags.js.rjs') }
          end
          return false
        end
      else
        @empty = true
        respond_to do |format|
          format.js { render :file => File.join(RAILS_ROOT, 'app/views/topics/add_tags.js.rjs') }
        end
        return false
      end
    end
  end
end
