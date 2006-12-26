class ImagesController < ApplicationController
  def index
    redirect_to :action => 'index', :controller => '/search', :current_class => 'Image', :all => true
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    redirect_to :action => 'index', :controller => '/search', :current_class => 'Image', :all => true
  end

  def show
    @image = Image.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :action => 'oai_record.rxml', :layout => false, :content_type => 'text/xml' }
    end
  end

  def new
    @image = Image.new
  end

  def create
    @image = Image.new(params[:image])
    # TODO: because id isn't available until after a save, we have a HACK
    # to add id into record during acts_as_zoom
    @image.oai_record = render_to_string(:template => 'images/oai_record',
                                         :layout => false)
    @successful = @image.save

    if params[:relate_to_topic_id] and @successful
      ContentItemRelation.new_relation_to_topic(params[:relate_to_topic_id], @image)
      # TODO: translation
      flash[:notice] = 'The image was successfully created.'
      # TODO: make this a helper
      redirect_to :action => 'show', :controller => '/topics', :id => params[:relate_to_topic_id]
    elsif @successful
      # TODO: translation
      flash[:notice] = 'The image was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @image = Image.find(params[:id])
  end

  def update
    @image = Image.find(params[:id])
    # TODO: because id isn't available until after a save, we have a HACK
    # to add id into record during acts_as_zoom
    @image.oai_record = render_to_string(:template => 'images/oai_record',
                                                   :layout => false)
    if @image.update_attributes(params[:image])
      flash[:notice] = 'Image was successfully updated.'
      redirect_to :action => 'show', :id => @image
    else
      render :action => 'edit'
    end
  end

  def destroy
    Image.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
