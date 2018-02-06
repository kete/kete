class AudioController < ApplicationController
  include ExtendedContentController
  include MayBeUploadAsServiceController

  def index
    redirect_to_search_for('AudioRecording')
  end

  def list
    respond_to do |format|
      format.html { redirect_to basket_audio_recording_index_path }
      format.rss do
        date = DateTime.parse(params[:updated_since]) if params[:updated_since]
        date = DateTime.now.beginning_of_month        if date.nil?

        @list_type = 'AudioRecording'
        @items = AudioRecording.updated_since(date)
        render 'shared/list'
      end
    end
  end

  def show
    @audio_recording = prepare_item_and_vars
    @comments = @audio_recording.non_pending_comments
    @creator = @audio_recording.creator
    @last_contributor = @audio_recording.contributors.last || @creator
    @related_item_topics = @audio_recording.related_items.select { |ri| ri.is_a? Topic }

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(item: @audio_recording) }
    end
  end

  def new
    @audio_recording = AudioRecording.new
  end

  def create
    @audio_recording = AudioRecording.new(audio_recording_params)
    @audio_recording.creator = current_user
    if @audio_recording.save
      @audio_recording.do_notifications_if_pending(1, current_user)
    end

    setup_related_topic_and_zoom_and_redirect(
      @audio_recording,
      nil,
      private: (params[:audio_recording][:private] == 'true')
    )
  end

  def edit
    @audio_recording = AudioRecording.find(params[:id])
    public_or_private_version_of(@audio_recording)
  end

  def update
    @audio_recording = AudioRecording.find(params[:id])
    version_after_update = @audio_recording.max_version + 1

    if @audio_recording.update_attributes(audio_recording_params)
      after_successful_zoom_item_update(@audio_recording, version_after_update)
      flash[:notice] = t('audio_controller.update.updated')

      redirect_to_show_for(@audio_recording, private: (audio_recording_params[:private] == 'true'))
    else
      render action: 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('AudioRecording', 'Audio recording')
  end

  private

  def audio_recording_params
    params.require(:audio_recording)
          .permit(:basket_id, :title, :description, :uploaded_data,
                  :tag_list, :version_comment, :raw_tag_list,
                  :related_items_position)
  end
end
