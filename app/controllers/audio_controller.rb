class AudioController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @audio_item_pages, @audio_items = paginate :audio_items, :per_page => 10
  end

  def show
    @audio_item = AudioItem.find(params[:id])
  end

  def new
    @audio_item = AudioItem.new
  end

  def create
    @audio_item = AudioItem.new(params[:audio_item])
    if @audio_item.save
      flash[:notice] = 'AudioItem was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @audio_item = AudioItem.find(params[:id])
  end

  def update
    @audio_item = AudioItem.find(params[:id])
    if @audio_item.update_attributes(params[:audio_item])
      flash[:notice] = 'AudioItem was successfully updated.'
      redirect_to :action => 'show', :id => @audio_item
    else
      render :action => 'edit'
    end
  end

  def destroy
    AudioItem.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
