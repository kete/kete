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
    @creator = @web_link.creators.first || User.find(1)
    @last_contributor = @web_link.contributors.last || @creator

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
    @successful = @web_link.save

    @web_link.creators << current_user

    setup_related_topic_and_zoom_and_redirect(@web_link)
  end

  def edit
    @web_link = WebLink.find(params[:id])
  end

  def update
    @web_link = WebLink.find(params[:id])

    if @web_link.update_attributes(params[:web_link])
      # add this to the user's empire of contributions
      # TODO: allow current_user whom is at least moderator to pick another user
      # as contributor
      # uses virtual attr as hack to pass version to << method
      @current_user = current_user
      @current_user.version = @web_link.version
      @web_link.contributors << @current_user

      prepare_and_save_to_zoom(@web_link)

      flash[:notice] = 'WebLink was successfully updated.'
      redirect_to :action => 'show', :id => @web_link
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('WebLink','Web link')
  end
end
