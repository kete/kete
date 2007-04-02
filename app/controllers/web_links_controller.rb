class WebLinksController < ApplicationController
  include ExtendedContentController

  def index
    redirect_to_search_for('WebLink')
  end

  def list
    index
  end

  def show
    if !has_all_fragments? or params[:format] == 'xml'
      @web_link = @current_basket.web_links.find(params[:id])
      @title = @web_link.title
    end

    if !has_fragment?({:part => 'contributions' }) or params[:format] == 'xml'
      @creator = @web_link.creators.first
      @last_contributor = @web_link.contributors.last || @creator
    end

    if !has_fragment?({:part => 'comments' }) or params[:format] == 'xml'
      @comments = @web_link.comments
    end

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @web_link) }
    end
  end

  def new
    @web_link = WebLink.new
  end

  def create
    @web_link = WebLink.new(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'web_link', :item_class => 'WebLink'))
    @successful = @web_link.save

    @web_link.creators << current_user

    setup_related_topic_and_zoom_and_redirect(@web_link)
  end

  def edit
    @web_link = WebLink.find(params[:id])
  end

  def update
    @web_link = WebLink.find(params[:id])

    if @web_link.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'web_link', :item_class => 'WebLink'))
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
