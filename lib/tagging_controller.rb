module TaggingController
  unless included_modules.include? TaggingController
    def self.included(klass)
      klass.send :auto_complete_for, :tag, :name
    end

    def add_tags
      # Kieran Pilkington, 2008/10/23
      # If we are updating via AJAX tag editor, then append the tags to the current tags list
      if !params[:tag].blank? && !params[:tag][:name].blank?
        @item = item_from_controller_and_id
        @item.tag_list = "#{@item.tag_list.join(", ")}, #{params[:tag][:name]}"
        @item.save
        @item.reload
        # I think it's nessesary to run this (update zoom db's with new tag?). Could be wrong?
        after_successful_zoom_item_update(@item)
        respond_to do |format|
          flash[:notice] = "The new tag(s) have been added to #{@item.title}"
          format.html { redirect_to_show_for @item, :private => (params[:private] == "true") }
          format.js { render :file => File.join(RAILS_ROOT, 'app/views/topics/add_tags.js.rjs') }
        end
      else
        respond_to do |format|
          flash[:notice] = "The new tag(s) failed to add to #{@item.title}"
          format.html { redirect_to_show_for @item, :private => (params[:private] == "true") }
          format.js { render :file => File.join(RAILS_ROOT, 'app/views/topics/add_tags.js.rjs') }
        end
      end
    end
  end
end
