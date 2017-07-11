class VideoController < ApplicationController
  include ExtendedContentController
  include MayBeUploadAsServiceController

  def index
    redirect_to_search_for('Video')
  end

  def list
    respond_to do |format|
      format.html { redirect_to basket_video_index_path }
      format.rss do 
        date = DateTime.parse(params[:updated_since]) if params[:updated_since]
        date = DateTime.now.beginning_of_month        if date.nil?

        @list_type = 'Video'
        @items = Video.updated_since(date)
        render 'shared/list'
      end
    end
  end

  def show
    @video = prepare_item_and_vars
    @comments = @video.non_pending_comments

    @creator = @video.creator
    @last_contributor = @video.contributors.last || @creator

    @related_item_topics = @video.related_items.select {|ri| ri.is_a? Topic}

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(item: @video) }
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
    if @successful
      @video.creator = current_user

      @video.do_notifications_if_pending(1, current_user)
    end
    setup_related_topic_and_zoom_and_redirect(@video, nil, private: (params[:video][:private] == 'true'))
  end

  def edit
    @video = Video.find(params[:id])
    public_or_private_version_of(@video)
  end

  def update
    @video = Video.find(params[:id])

    version_after_update = @video.max_version + 1

    @video.attributes = params[:video]
    @successful = @video.save

    if @successful

      after_successful_zoom_item_update(@video, version_after_update)
      flash[:notice] = t('video_controller.update.updated')

      redirect_to_show_for(@video, private: (params[:video][:private] == 'true'))
    else
      render action: 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('Video')
  end

end
