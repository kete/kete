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
    # TODO: because id isn't available until after a save, we have a HACK
    # to add id into record during acts_as_zoom
    @video.oai_record = render_to_string(:template => 'video/oai_record',
                                                   :layout => false)
    @video.basket_urlified_name = @current_basket.urlified_name
    @successful = @video.save

    # add this to the user's empire of creations
    # TODO: allow current_user whom is at least moderator to pick another user
    # as creator
    @video.creators << current_user

    if params[:relate_to_topic_id] and @successful
      ContentItemRelation.new_relation_to_topic(params[:relate_to_topic_id], @video)
      # TODO: translation
      flash[:notice] = 'The video was successfully created.'
      redirect_to_related_topic(params[:relate_to_topic_id])
    elsif @successful
      # TODO: translation
      flash[:notice] = 'The video was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @video = Video.find(params[:id])
  end

  def update
    @video = Video.find(params[:id])
    # TODO: because id isn't available until after a save, we have a HACK
    # to add id into record during acts_as_zoom
    @video.oai_record = render_to_string(:template => 'video/oai_record',
                                                   :layout => false)
    if @video.update_attributes(params[:video])
      # add this to the user's empire of contributions
      # TODO: allow current_user whom is at least moderator to pick another user
      # as contributor
      # uses virtual attr as hack to pass version to << method
      @current_user = current_user
      @current_user.version = @video.version
      @video.contributors << @current_user

      flash[:notice] = 'Video was successfully updated.'
      redirect_to :action => 'show', :id => @video
    else
      render :action => 'edit'
    end
  end

  def destroy
    # TODO: use the code in topics_controller
    Video.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
