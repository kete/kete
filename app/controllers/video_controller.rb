class VideoController < ApplicationController
  include ExtendedContentController

  def index
    redirect_to_search_for('Video')
  end

  def list
    index
  end

  def show
    if !has_all_fragments? or params[:format] == 'xml'
      @video = @current_basket.videos.find(params[:id])
      @title = @video.title
    end

    if !has_fragment?({:part => 'contributions' }) or params[:format] == 'xml'
      @creator = @video.creators.first
      @last_contributor = @video.contributors.last || @creator
    end

    if !has_fragment?({:part => 'comments' }) or !has_fragment?({:part => 'comments-moderators' }) or params[:format] == 'xml'
      @comments = @video.comments
    end

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @video) }
    end
  end

  def new
    @video = Video.new
  end

  def create
    @video = Video.new(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'video', :item_class => 'Video'))
    @successful = @video.save


    # add this to the user's empire of creations
    # TODO: allow current_user whom is at least moderator to pick another user
    # as creator
    @video.add_as_creator(current_user) if @successful

    setup_related_topic_and_zoom_and_redirect(@video)
  end

  def edit
    @video = Video.find(params[:id])
  end

  def update
    @video = Video.find(params[:id])

    if @video.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'video', :item_class => 'Video'))

      after_successful_zoom_item_update(@video)

      flash[:notice] = 'Video was successfully updated.'

      redirect_to_show_for(@video)
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
