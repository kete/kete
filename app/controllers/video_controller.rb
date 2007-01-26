class VideoController < ApplicationController
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    redirect_to_search_for('Video')
  end

  def list
    index
  end

  def show
    @video = @current_basket.videos.find(params[:id])
    @title = @video.title
    @creator = @video.creators.first
    @last_contributor = @video.contributors.last || @creator

    respond_to do |format|
      format.html
      format.xml { render :action => 'oai_record.rxml', :layout => false, :content_type => 'text/xml' }
    end
  end

  def new
    @video = Video.new
  end

  def create
    @video = Video.new(params[:video])
    @successful = @video.save

    # add this to the user's empire of creations
    # TODO: allow current_user whom is at least moderator to pick another user
    # as creator
    @video.creators << current_user

    setup_related_topic_and_zoom_and_redirect(@video)
  end

  def edit
    @video = Video.find(params[:id])
  end

  def update
    @video = Video.find(params[:id])

    if @video.update_attributes(params[:video])
      # add this to the user's empire of contributions
      # TODO: allow current_user whom is at least moderator to pick another user
      # as contributor
      # uses virtual attr as hack to pass version to << method
      @current_user = current_user
      @current_user.version = @video.version
      @video.contributors << @current_user

      prepare_and_save_to_zoom(@video)

      flash[:notice] = 'Video was successfully updated.'
      redirect_to :action => 'show', :id => @video
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('Video')
  end
end
