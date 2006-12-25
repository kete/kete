class WebLinksController < ApplicationController
  def index
    redirect_to :action => 'index', :controller => '/search', :current_class => 'WebLink', :all => true
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    redirect_to :action => 'index', :controller => '/search', :current_class => 'WebLink', :all => true
  end

  def show
    @web_link = WebLink.find(params[:id])
    respond_to do |format|
      format.html
      format.xml { render :action => 'oai_record.rxml', :layout => false, :content_type => 'text/xml' }
    end
  end

  def new
    @web_link = WebLink.new
  end

  def create
    @web_link = WebLink.new(params[:web_link])
    # TODO: because id isn't available until after a save, we have a HACK
    # to add id into record during acts_as_zoom
    @web_link.oai_record = render_to_string(:template => 'web_links/oai_record',
                                            :layout => false)
    @successful = @web_link.save

    if params[:relate_to_topic_id] and @successful
      ContentItemRelation.new_relation_to_topic(params[:relate_to_topic_id], @web_link)
      # TODO: translation
      flash[:notice] = 'The web link was successfully created.'
      # TODO: make this a helper
      redirect_to :action => 'show', :controller => '/topics', :id => params[:relate_to_topic_id]
    elsif @successful
      flash[:notice] = 'WebLink was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @web_link = WebLink.find(params[:id])
  end

  def update
    @web_link = WebLink.find(params[:id])
    # TODO: because id isn't available until after a save, we have a HACK
    # to add id into record during acts_as_zoom
    @web_link.oai_record = render_to_string(:template => 'web_links/oai_record',
                                            :layout => false)
    if @web_link.update_attributes(params[:web_link])
      flash[:notice] = 'WebLink was successfully updated.'
      redirect_to :action => 'show', :id => @web_link
    else
      render :action => 'edit'
    end
  end

  def destroy
    begin
      @web_link = WebLink.find(params[:id])
      @web_link.oai_record = render_to_string(:template => 'web_links/oai_record',
                                         :layout => false)
      @successful = @web_link.destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    if @successful
      flash[:notice] = 'Web link was successfully deleted.'
    end
    redirect_to :action => 'list'
  end
end
