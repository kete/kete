module ImageSlideshow
  unless included_modules.include? ImageSlideshow
    def self.included(klass)
      Rails.logger.info klass.name
      if klass.name == 'TopicsController'
        klass.send :before_filter, :selected_image, :only => ['show', 'topics_slideshow_div_update']
      else
        klass.send :before_filter, :selected_image, :only => ['index']
      end
      klass.helper_method :slideshow_div
    end

    def topics_slideshow_div_update
      render :text => slideshow_div
    end

    def slideshow_div
      html = @template.content_tag('div', render_selected_image, { :id => "selected-image-display" })
      html += @template.periodically_call_remote(:update => 'selected-image-display',
                                                 :url => { :action => 'selected_image', :id => (params[:controller] == 'topics') ? params[:id] : nil },
                                                 :frequency => 15)
      html
    end

    def selected_image
      slideshow.reset! if params[:action] == 'topics_slideshow_div_update'

      # get next url from slideshow, if slideshow exists,
      # or this url is the last url in results
      # otherwise, create a new slide show based on basket settings

      # reformat into a standard_url, for results comparison in slideshow
      if params[:controller] == 'topics'
        url_hash = { :controller => 'topics', :action => 'selected_image' }
      else
        url_hash = { :controller => 'index_page', :action => 'selected_image' }
      end
      @current_url = url_for(url_hash.merge(:id => params[:id]))

      # hash keys have to be strings
      # so as not to trip up later comparisons
      slideshow_key = { "basket" => @current_basket.id,
        "order" => @current_basket.index_page_image_as,
        "zoom_class" => 'StillImage' }

      if !session[:slideshow].blank? && slideshow.key == slideshow_key && !slideshow.in_set?(@current_url) && !slideshow.last_requested.blank?
        @current_url = slideshow.after(slideshow.last_requested)
      end

      id_string = @current_url.split("/").last
      if id_string =~ /([0-9]+)/
        @current_id = $1
      else
        @current_id = nil
      end

      @selected_still_image = nil

      if !session[:slideshow].blank? && slideshow.in_set?(@current_url) && slideshow.key == slideshow_key
        @selected_still_image = still_image_from_slideshow
      else
        # put together results
        # normally results are paged
        # and when you hit the last result in a page
        # the next page of results is built or something like that
        # and they are derived by hitting search controller

        @still_image_ids = params[:controller] == 'topics' ? find_related_images : find_basket_images

        session[:slideshow] = nil
        if !@still_image_ids.blank?
          total_images = @still_image_ids.size
          slideshow.key = slideshow_key
          slideshow.results = @still_image_ids.collect { |id| url_for(url_hash.merge(:id => id)) }
          slideshow.total = total_images
          slideshow.total_pages = 1
          slideshow.current_page = 1
          slideshow.number_per_page = total_images
          @current_id = @still_image_ids.first
          @selected_still_image = StillImage.find(@current_id)
          @current_url = url_for(url_hash.merge(:id => @current_id))
        end
      end

      @selected_image_file = ImageFile.find_by_thumbnail_and_still_image_id('medium', @selected_still_image ) if !@selected_still_image.nil?

      if !session[:slideshow].blank? && !slideshow.results.nil?
        @previous_url = slideshow.in_set?(@current_url) ? slideshow.before(@current_url) : nil
        @next_url = slideshow.in_set?(@current_url) ? slideshow.after(@current_url) : nil

        # keep track of where we are in the results
        slideshow.last_requested = !slideshow.last?(@current_url) ? @current_url : nil
      else
        @previous_url = nil
        @next_url = nil
      end

      # get still image and image_file
      if request.xhr?
        render_selected_image
      else
        if params[:action] == 'selected_image'
          redirect_to params.merge(:action => (params[:controller] == 'topics') ? 'show' : 'index')
        end
      end
    end

    def still_image_from_slideshow
      still_image_collection.find_by_id((@current_id || params[:id]))
    end

    private

    def still_image_collection
      @still_image_collection ||= @current_basket != @site_basket ? @current_basket.still_images : StillImage
    end

    def find_basket_images(limit=20)
      find_args_hash = { :select => 'id, title, created_at', :limit => limit }
      # We have to make sure the image is public on the site basket, or if they dont have permission to view it
      # there is no way to get all private from the site basket and public from others without another query
      find_args_hash.merge!(:conditions => ["(#{PUBLIC_CONDITIONS}) AND (file_private = :file_private OR file_private is null)",
                                            { :file_private => false }]) unless display_private_items?
      # Order results acording to the basket setting
      find_args_hash[:order] = @current_basket.index_page_image_as == 'random' ? :random : 'created_at desc'
      # Execute the find
      still_image_collection.find(:all, find_args_hash)
    end

    def find_related_images(limit=20)
      find_args_hash = { :select => 'still_images.id, still_images.title, still_images.created_at', :limit => limit }
      # We have to make sure the image is public on the site basket, or if they dont have permission to view it
      # there is no way to get all private from the site basket and public from others without another query
      find_args_hash.merge!(:conditions => ["(#{PUBLIC_CONDITIONS}) AND (file_private = :file_private OR file_private is null)",
                                            { :file_private => false }]) unless display_private_items?
      # Execute the find
      Topic.find_by_id(params[:id]).still_images.find(:all, find_args_hash)
    end

    def render_selected_image
      render :partial =>'index_page/selected_image',
             :locals => { :selected_image_file => @selected_image_file,
                          :previous_url => @previous_url,
                          :next_url => @next_url,
                          :selected_still_image => @selected_still_image }
    end

    def display_private_items?
      @display_private_items ||= @current_basket.show_privacy_controls_with_inheritance? && \
                                    permitted_to_view_private_items?
    end

  end
end
