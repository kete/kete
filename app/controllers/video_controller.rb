class VideoController < ApplicationController
  include ExtendedContentController
  
  helper :privacy_controls

  def index
    redirect_to_search_for('Video')
  end

  def list
    index
  end

  def show
    if logged_in? && permitted_to_view_private_items?

      @video = @current_basket.videos.find(params[:id])
      @video = @video.private_version! if @video.has_private_version? && params[:private] == "true"
      
      # Show the privacy chooser
      @show_privacy_chooser = true
    
    elsif !has_all_fragments? or params[:format] == 'xml'
      @video = @current_basket.videos.find(params[:id])
      @title = @video.title
    end

    if !has_fragment?({:part => 'contributions' }) or params[:format] == 'xml'
      @creator = @video.creator
      @last_contributor = @video.contributors.last || @creator
    end

    if @video.private? or !has_fragment?({:part => 'comments' }) or !has_fragment?({:part => 'comments-moderators' }) or params[:format] == 'xml'
      @comments = @video.non_pending_comments
    end

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @video) }
    end
  end

  def new
    @video = Video.new({ :private => @current_basket.private_default || false, 
                         :file_private =>  @current_basket.file_private_default || false })
  end

  def create
    @video = Video.new(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'video', :item_class => 'Video'))
    @successful = @video.save


    # add this to the user's empire of creations
    # TODO: allow current_user whom is at least moderator to pick another user
    # as creator
    if @successful
      @video.creator = current_user

      @video.do_notifications_if_pending(1, current_user)
    end
    setup_related_topic_and_zoom_and_redirect(@video, nil, :private => (params[:video][:private] == "true"))
  end

  def edit
    @video = Video.find(params[:id])
    public_or_private_version_of(@video)
  end

  def update
    @video = Video.find(params[:id])

    if @video.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'video', :item_class => 'Video'))

      after_successful_zoom_item_update(@video)

      @video.do_notifications_if_pending(@video.max_version, current_user)
      flash[:notice] = 'Video was successfully updated.'

      redirect_to_show_for(@video, :private => (params[:video][:private] == "true"))
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('Video')
  end

  private
  def load_content_type
    @content_type = ContentType.find_by_class_name('Video')
  end

end
