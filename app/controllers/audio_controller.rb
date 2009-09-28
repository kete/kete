class AudioController < ApplicationController
  include ExtendedContentController

  def index
    redirect_to_search_for('AudioRecording')
  end

  def list
    index
  end

  def show
    @audio_recording = prepare_item_and_vars

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @audio_recording) }
    end
  end

  def new
    @audio_recording = AudioRecording.new
  end

  def create
    @audio_recording = AudioRecording.new(params[:audio_recording])

    @successful = @audio_recording.save

    # add this to the user's empire of creations
    # TODO: allow current_user whom is at least moderator to pick another user
    # as creator
    if @successful
      @audio_recording.creator = current_user

      @audio_recording.do_notifications_if_pending(1, current_user)
    end

    setup_related_topic_and_zoom_and_redirect(@audio_recording, nil, :private => (params[:audio_recording][:private] == "true"))
  end

  def edit
    @audio_recording = AudioRecording.find(params[:id])
    public_or_private_version_of(@audio_recording)
  end

  def update
    @audio_recording = AudioRecording.find(params[:id])

    version_after_update = @audio_recording.max_version + 1

    @successful = ensure_no_new_insecure_elements_in('audio_recording')
    @audio_recording.attributes = params[:audio_recording]
    @successful = @audio_recording.save if @successful

    if @successful

      after_successful_zoom_item_update(@audio_recording, version_after_update)
      flash[:notice] = t('audio_controller.update.updated')

      redirect_to_show_for(@audio_recording, :private => (params[:audio_recording][:private] == "true"))
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('AudioRecording','Audio recording')
  end
end
