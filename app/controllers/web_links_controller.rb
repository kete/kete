class WebLinksController < ApplicationController
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    redirect_to_search_for('WebLink')
  end

  def list
    index
  end

  def show
    @web_link = @current_basket.web_links.find(params[:id])
    @title = @web_link.title
    @creator = @web_link.creators.first
    @last_contributor = @web_link.contributors.last

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
    @web_link.basket_urlified_name = @current_basket.urlified_name
    @successful = @web_link.save

    if params[:relate_to_topic_id] and @successful
      ContentItemRelation.new_relation_to_topic(params[:relate_to_topic_id], @web_link)
      # TODO: translation
      flash[:notice] = 'The web link was successfully created.'
      redirect_to_related_topic(params[:relate_to_topic_id])
    elsif @successful
      # add this to the user's empire of creations
      # TODO: allow current_user whom is at least moderator to pick another user
      # as creator
      @web_link.creators << current_user

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
      # add this to the user's empire of contributions
      # TODO: allow current_user whom is at least moderator to pick another user
      # as contributor
      # uses virtual attr as hack to pass version to << method
      @current_user = current_user
      @current_user.version = @web_link.version
      @web_link.contributors << @current_user

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
      @web_link.basket_urlified_name = @web_link.basket.urlified_name
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
