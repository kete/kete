class AudioController < ApplicationController
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    redirect_to_search_for('AudioRecording')
  end

  def list
    index
  end

  def show
    @audio_recording = @current_basket.audio_recordings.find(params[:id])
    @title = @audio_recording.title
    respond_to do |format|
      format.html
      format.xml { render :action => 'oai_record.rxml', :layout => false, :content_type => 'text/xml' }
    end
  end

  def new
    # TODO: this is just for show, redo as specified
    if @current_basket.id == 1
      permit "member or admin of :current_basket" do
        @audio_recording = AudioRecording.new
      end
    else
      permit "admin of :current_basket" do
        @audio_recording = AudioRecording.new
      end
    end
  end

  def create
    @audio_recording = AudioRecording.new(params[:audio_recording])
    # TODO: because id isn't available until after a save, we have a HACK
    # to add id into record during acts_as_zoom
    @audio_recording.oai_record = render_to_string(:template => 'audio/oai_record',
                                                   :layout => false)
    @audio_recording.basket_urlified_name = @current_basket.urlified_name
    @successful = @audio_recording.save

    # add this to the user's empire of creations
    # TODO: allow current_user whom is at least moderator to pick another user
    # as creator
    @audio_recording.creators << current_user
    if params[:relate_to_topic_id] and @successful
      ContentItemRelation.new_relation_to_topic(params[:relate_to_topic_id], @audio_recording)
      # TODO: translation
      flash[:notice] = 'The audio recording was successfully created.'
      redirect_to_related_topic(params[:relate_to_topic_id])
    elsif @successful
      # TODO: translation
      flash[:notice] = 'The audio recording was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @audio_recording = AudioRecording.find(params[:id])
  end

  def update
    @audio_recording = AudioRecording.find(params[:id])
    # TODO: because id isn't available until after a save, we have a HACK
    # to add id into record during acts_as_zoom
    @audio_recording.oai_record = render_to_string(:template => 'audio/oai_record',
                                                   :layout => false)
    if @audio_recording.update_attributes(params[:audio_recording])
      # add this to the user's empire of contributions
      # TODO: allow current_user whom is at least moderator to pick another user
      # as contributor
      # uses virtual attr as hack to pass version to << method
      @current_user = current_user
      @current_user.version = @audio_recording.version
      @audio_recording.contributors << @current_user

      flash[:notice] = 'AudioRecording was successfully updated.'
      redirect_to :action => 'show', :id => @audio_recording
    else
      render :action => 'edit'
    end
  end

  def destroy
    # TODO: use the code in topics_controller
    AudioRecording.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

end
