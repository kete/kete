class AudioController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @audio_recording_pages, @audio_recordings = paginate :audio_recordings, :per_page => 10
  end

  def show
    @audio_recording = AudioRecording.find(params[:id])
  end

  def new
    @audio_recording = AudioRecording.new
  end

  def create
    @audio_recording = AudioRecording.new(params[:audio_recording])
    if @audio_recording.save
      flash[:notice] = 'AudioRecording was successfully created.'
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
    if @audio_recording.update_attributes(params[:audio_recording])
      flash[:notice] = 'AudioRecording was successfully updated.'
      redirect_to :action => 'show', :id => @audio_recording
    else
      render :action => 'edit'
    end
  end

  def destroy
    AudioRecording.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
