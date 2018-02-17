module ImageSlideshow
  unless included_modules.include? ImageSlideshow
    def self.included(klass)
      if klass.name == 'TopicsController'
        klass.send :before_filter, :prepare_slideshow, only: ['selected_image']
      else
        klass.send :before_filter, :prepare_slideshow, only: ['index', 'selected_image']
      end
      klass.helper_method :slideshow_div, :slideshow_updater
    end

    # Containing selected-image-display div, with slideshow_updater unless in topic slideshow
    # We have to use @template.content_tag in this case because we don't have direct access to
    # view helpers in this scope
    def slideshow_div
      html = @template.content_tag('div', render_selected_image, { id: 'selected-image-display' })
      html += slideshow_updater unless topic_slideshow?
      html
    end

    # Javascript tag that updates selected-image-display every 15 seconds
    # We have to use @template.periodically... in this case because we don't
    # have direct access to view helpers in this scope
    def slideshow_updater
      update_id = (topic_slideshow? ? 'related_items_slideshow' : 'selected-image-display')
      @template.periodically_call_remote(
        update: update_id,
        url: {
          action: 'selected_image',
          topic_id: topic_slideshow? ? params[:id] : nil
        },
        frequency: 15,
        method: 'get',
        before: "if (!$('selected-image-display') || $('selected-image-display-paused')) { return false; }"
      )
    end

    # The action slideshow_updater requests. Returns either the next image display,
    # or redirect if they are viewing the image directly (which normally shouldn't happen)
    def selected_image
      if request.xhr?
        render text: (topic_slideshow? ? slideshow_div : render_selected_image)
      else
        redirect_to params.merge(action: topic_slideshow? ? 'show' : 'index')
      end
    end

    private

    # Render the selected image partial, passing in various params
    # We have to use @template.render in this case because we don't
    # have direct access to view helpers in this scope (and because
    # render in a template will stop the page processing, instead
    # of parsing and returning a string)
    def render_selected_image
      @template.render 'index_page/selected_image',
                       selected_image_file: @selected_image_file,
                       previous_url: @previous_url,
                       next_url: @next_url,
                       selected_still_image: @selected_still_image
    end

    def topic_slideshow?
      (params[:controller] == 'topics')
    end

    def url_hash
      controller = topic_slideshow? ? 'topics' : 'index_page'
      { controller: controller, action: 'selected_image' }
    end

    # Helps make sure conflicts between different slideshows don't occur
    # hash keys have to be strings so as not to trip up later comparisons
    def slideshow_key
      key = {
        'basket' => @current_basket.id,
        'order' => @current_basket.index_page_image_as,
        'zoom_class' => 'StillImage'
      }
      key['slideshow_topic_id'] = params[:topic_id].to_i if topic_slideshow?
      key
    end

    def slideshow_has_results?
      (!session[:image_slideshow].blank? && !image_slideshow.results.nil?)
    end

    # Does this slideshow key match that of the previous slideshow in our session
    # If it doesn't, it'll be repopulated later on
    def slideshow_key_valid?
      image_slideshow.key == slideshow_key
    end

    # Prepare the slideshow. Before filter on index_page index, topic show, and selected_image action calls.
    # We have to account for the different URL's that request this method.
    # Auto updated (slideshow) requests only this method (no id passed in). So we have to get the next result ourselved
    # Previous/next links however do pass in an id to this method, which means we should respect that and not overwrite it
    def prepare_slideshow
      # Reset a few instance vars
      @current_id = @selected_still_image = @previous_url = @next_url = nil

      # create a url based on the current request. It only contains an id when the user has
      # clicked on either the next or previous buttons. The rest of the time, no id
      @current_url = url_for(url_hash.merge(id: params[:id]))

      # If slideshow has results already, and it matches the last viewed slideshow
      if slideshow_has_results? && slideshow_key_valid?
        # Check if the current url is not in the slideshow (i.e. when no id is passed in, it won't be), and when
        # the last requested image is not blank, update the current_url to the next image in the slideshow
        @current_url = image_slideshow.next if !image_slideshow.in_set?(@current_url) && !image_slideshow.last_requested.blank?
        # Now that we have a @current_url from whatever url requested it (auto update, next,
        # previous links etc), check to see if that url is in the results
        if image_slideshow.in_set?(@current_url)
          # Extract the id of that image from the @current_url
          @current_id = $1 if @current_url.split('/').last =~ /([0-9]+)(.*)/
        else
          # The current_url is not in the results (possible corrupt data)
          # so lets populate new data
          populate_slideshow
        end
      else
        # no previous valid results, populate new ones
        populate_slideshow
      end

      # We have populated results by now hopefully
      if slideshow_has_results?
        # Get the current still image
        @selected_still_image = still_image_collection.find_by_id(@current_id)

        # At this point, we have a valid still image we should be displaying. Get the ImageFile for it
        # EOIN: I am commenting this line out for the moment to get this controller working
        # @selected_image_file = @selected_still_image.send("#{SystemSetting.image_slideshow_size.to_s}_file") if !@selected_still_image.nil?

        # Setup the previous and next url links the user can use
        @previous_url = image_slideshow.previous(@current_url)
        @next_url = image_slideshow.next(@current_url)
        # Keep track of where we are in the results
        image_slideshow.last_requested = !image_slideshow.last?(@current_url) ? @current_url : nil
      end
    end

    # Put together results and populate the slideshow.
    def populate_slideshow
      # Get either this baskets images, or the related images if we're in a topic
      @still_image_ids = topic_slideshow? ? find_related_images : find_basket_images
      session[:image_slideshow] = nil
      if !@still_image_ids.blank?
        total_images = @still_image_ids.size
        image_slideshow.key = slideshow_key
        image_slideshow.results = @still_image_ids.collect { |id| url_for(url_hash.merge(id: id)) }
        image_slideshow.total = total_images
        image_slideshow.total_pages = 1
        image_slideshow.current_page = 1
        image_slideshow.number_per_page = total_images
        # Set the current id to the first still image result
        @current_id = @still_image_ids.first
        @current_url = url_for(url_hash.merge(id: @current_id))
      end
    end

    # If we're in the site basket, return all images on the site,
    # otherwise, scope results to the current basket
    def still_image_collection
      @still_image_collection ||= @current_basket != @site_basket && !topic_slideshow? ? @current_basket.still_images : StillImage
    end

    # Should we display private images to the user? Only if privacy
    # controls are enabled and the current user is able to view them
    def display_private_items?
      @display_private_items ||= @current_basket.show_privacy_controls_with_inheritance? && \
                                 permitted_to_view_private_items?
    end

    # We have to make sure the images we get are either in baskets we have access to, or publicly viewable images
    def public_conditions
      prefix = topic_slideshow? ? 'still_images.' : ''
      { conditions: [
        "((#{prefix}basket_id IN (:basket_ids)) OR ((#{PUBLIC_CONDITIONS}) AND (#{prefix}file_private = :file_private OR #{prefix}file_private is null)))",
        { basket_ids: @basket_access_hash.collect { |b| b[1][:id] }, file_private: false }] }
    end

    # Finds all basket images scoped to the correct still image collection
    def find_basket_images(limit = 20)
      find_args_hash = { select: 'id, title, created_at, basket_id, file_private', limit: limit }
      find_args_hash.merge!(public_conditions) unless display_private_items?
      # Order results acording to the basket setting
      find_args_hash[:order] = @current_basket.index_page_image_as == 'random' ? 'RANDOM()' : 'created_at desc'
      # Execute the find in a collection of still images depending on current basket
      still_image_collection.find(:all, find_args_hash)
    end

    # Finds all basket images scoped to the current topic
    def find_related_images(limit = 20)
      raise 'ERROR: Tried to populate topic slideshow without passing in params[:topic_id]' unless params[:topic_id]
      find_args_hash = { select: 'still_images.id, still_images.title, still_images.created_at, still_images.basket_id, still_images.file_private', limit: limit }
      find_args_hash.merge!(public_conditions) unless display_private_items?
      find_args_hash[:order] = 'still_images.created_at desc'
      # Execute the find on the current topics still images
      topic = Topic.find_by_id(params[:topic_id]) # use find_by_id() instead of find() so we don't want to raise an error
      topic ? topic.still_images.find(:all, find_args_hash) : []
    end

  end
end
