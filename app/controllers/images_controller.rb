class ImagesController < ApplicationController
  def index
    redirect_to :action => 'index', :controller => '/search', :current_class => 'StillImage', :all => true
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    redirect_to :action => 'index', :controller => '/search', :current_class => 'StillImage', :all => true
  end

  def show
    @still_image = StillImage.find(params[:id])
    @view_size = params[:view_size] || "medium"
    @image_file = ImageFile.find_by_thumbnail_and_still_image_id(@view_size, @still_image)
    respond_to do |format|
      format.html
      format.xml { render :action => 'oai_record.rxml', :layout => false, :content_type => 'text/xml' }
    end
  end

  def new
    @still_image = StillImage.new
  end

  def create
    @still_image = StillImage.new(params[:still_image])
    # TODO: because id isn't available until after a save, we have a HACK
    # to add id into record during acts_as_zoom
    @still_image.oai_record = render_to_string(:template => 'images/oai_record',
                                               :layout => false)
    @successful = @still_image.save

    if @successful
      @original_file = ImageFile.new(params[:image_file])
      @original_file.still_image_id = @still_image.id
      @original_file.save
      # attachment_fu doesn't insert our still_image_id into the thumbnails
      # automagically
      @original_file.thumbnails.each do |thumb|
        thumb.still_image_id = @still_image
        thumb.save!
      end
    end

    if params[:relate_to_topic_id] and @successful
      ContentItemRelation.new_relation_to_topic(params[:relate_to_topic_id], @still_image)
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
    @still_image = StillImage.find(params[:id])
  end

  def update
    @still_image = StillImage.find(params[:id])
    # TODO: because id isn't available until after a save, we have a HACK
    # to add id into record during acts_as_zoom
    @still_image.oai_record = render_to_string(:template => 'images/oai_record',
                                                   :layout => false)
    if @still_image.update_attributes(params[:still_image])
      if !params[:image_file][:uploaded_file].blank?
        # if they have uploaded something new, insert it
        @original_file = ImageFile.update_attributes(params[:image_file])
      end

      flash[:notice] = 'Image was successfully updated.'
      redirect_to :action => 'show', :id => @still_image
    else
      render :action => 'edit'
    end
  end

  def destroy
    StillImage.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
