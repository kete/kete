class ImagesController < ApplicationController
  include ExtendedContentController

  def index
    redirect_to_search_for('StillImage')
  end

  def list
    index
  end

  def show
    if !has_all_fragments? or params[:format] == 'xml'
      @still_image = @current_basket.still_images.find(params[:id])
      @title = @still_image.title
    end

    @view_size = params[:view_size] || "medium"
    @image_file = ImageFile.find_by_thumbnail_and_still_image_id(@view_size, params[:id])

    if !has_fragment?({:part => 'contributions' }) or params[:format] == 'xml'
      @creator = @still_image.creator
      @last_contributor = @still_image.contributors.last || @creator
    end

    if !has_fragment?({:part => 'comments' }) or !has_fragment?({:part => 'comments-moderators' }) or params[:format] == 'xml'
      @comments = @still_image.comments
    end

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @still_image) }
    end
  end

  def new
    @still_image = StillImage.new
  end

  def create
    @still_image = StillImage.new
    # handle problems with image file first
    @image_file = ImageFile.new(params[:image_file])
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

        # attachment_fu doesn't insert our still_image_id into the thumbnails
        # automagically
        @image_file.thumbnails.each do |thumb|
          thumb.still_image_id = @still_image.id
          thumb.save!
        end
      end

      setup_related_topic_and_zoom_and_redirect(@still_image)
    else
      render :action => 'new'
    end
  end

  def edit
    @still_image = StillImage.find(params[:id])
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

      @still_image.do_notifications_if_pending(version_after_update, current_user)

      flash[:notice] = 'Image was successfully updated.'

      redirect_to_show_for(@still_image)
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('StillImage','Image')
  end
end
