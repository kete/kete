class ImagesController < ApplicationController
  include ExtendedContentController
  
  helper :privacy_controls

  def index
    redirect_to_search_for('StillImage')
  end

  def list
    index
  end
  
  def show
    # Walter McGinnis, 2008-02-14
    # always loading still_image for the timebeing, since we check for blank version
    # to determine whether to show image file
    @still_image = @current_basket.still_images.find(params[:id])

    if permitted_to_view_private_items?
      @show_privacy_chooser = true
    end

    if !has_all_fragments? or (permitted_to_view_private_items? and params[:private] == "true") or params[:format] == 'xml'
      if permitted_to_view_private_items?
        @still_image = @still_image.private_version! if @still_image.has_private_version? && params[:private] == "true"
      end

      if !has_fragment?({:part => ("page_title_" + (params[:private] == "true" ? "private" : "public")) }) or params[:format] == 'xml'
        @title = @still_image.title
      end

      if !has_fragment?({:part => ("contributor_" + (params[:private] == "true" ? "private" : "public")) }) or params[:format] == 'xml'
        @creator = @still_image.creator
        @last_contributor = @still_image.contributors.last || @creator
      end

      if logged_in? and @at_least_a_moderator
        if !has_fragment?({:part => ("comments-moderators_" + (params[:private] == "true" ? "private" : "public"))}) or params[:format] == 'xml'
          @comments = @still_image.non_pending_comments
        end
      else
        if !has_fragment?({:part => ("comments_" + (params[:private] == "true" ? "private" : "public"))}) or params[:format] == 'xml'
          @comments = @still_image.non_pending_comments
        end
      end
    end

    @view_size = params[:view_size] || "medium"
    @image_file = ImageFile.find_by_thumbnail_and_still_image_id(@view_size, params[:id])

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @still_image) }
    end
  end

  def new
    @still_image = StillImage.new({ :private => @current_basket.private_default || false, 
                                    :file_private =>  @current_basket.file_private_default || false })
  end

  def create
    @still_image = StillImage.new
    # handle problems with image file first
    @image_file = ImageFile.new(params[:image_file].merge({ :file_private => params[:still_image][:file_private] }))
    @successful = @image_file.save

    if @successful

      @still_image = StillImage.new(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'still_image', :item_class => 'StillImage'))
      @successful = @still_image.save

      if @successful
        # add this to the user's empire of creations
        # TODO: allow current_user whom is at least moderator to pick another user
        # as creator
        @still_image.creator = current_user

        @still_image.do_notifications_if_pending(1, current_user)

        @image_file.still_image_id = @still_image.id
        @image_file.save
        
        # Set the file privacy ahead of time so AttachmentFuOverload can find the value..# attachment_fu doesn't insert our still_image_id into the thumbnails
        # automagically
        @image_file.thumbnails.each do |thumb|
          thumb.still_image_id = @still_image.id
          thumb.save!
        end
      end

      setup_related_topic_and_zoom_and_redirect(@still_image, nil, :private => (params[:still_image][:private] == "true"))
    else
      render :action => 'new'
    end
  end

  def edit
    @still_image = StillImage.find(params[:id])
    public_or_private_version_of(@still_image)
  end

  def update
    @still_image = StillImage.find(params[:id])

    version_after_update = @still_image.max_version + 1

    if @still_image.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'still_image', :item_class => 'StillImage'))

      if !params[:image_file][:uploaded_data].blank?
        # if they have uploaded something new, insert it
        @image_file = ImageFile.update_attributes(params[:image_file])
      end

      after_successful_zoom_item_update(@still_image)

      @still_image.do_notifications_if_pending(version_after_update, current_user) if 
        @still_image.versions.exists?(:version => version_after_update)

      flash[:notice] = 'Image was successfully updated.'

      redirect_to_show_for(@still_image, :private => (params[:still_image][:private] == "true"))
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('StillImage','Image')
  end
end
