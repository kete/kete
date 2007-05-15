class DocumentsController < ApplicationController
  include ExtendedContentController

  def index
    redirect_to_search_for('Document')
  end

  def list
    index
  end

  def show
    if !has_all_fragments? or params[:format] == 'xml'
      @document = @current_basket.documents.find(params[:id])
      @title = @document.title
    end

    if !has_fragment?({:part => 'contributions' }) or params[:format] == 'xml'
      @creator = @document.creators.first
      @last_contributor = @document.contributors.last || @creator
    end

    if !has_fragment?({:part => 'comments' }) or !has_fragment?({:part => 'comments-moderators' }) or params[:format] == 'xml'
      @comments = @document.comments
    end

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @document) }
    end
  end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'document', :item_class => 'Document'))
    @successful = @document.save

    # add this to the user's empire of creations
    # TODO: allow current_user whom is at least moderator to pick another user
    # as creator
    @document.creators << current_user if @successful

    setup_related_topic_and_zoom_and_redirect(@document)
  end

  def edit
    @document = Document.find(params[:id])
  end

  def update
    @document = Document.find(params[:id])

    if @document.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'document', :item_class => 'Document'))
      # add this to the user's empire of contributions
      # TODO: allow current_user whom is at least moderator to pick another user
      # as contributor
      # uses virtual attr as hack to pass version to << method
      @current_user = current_user
      @current_user.version = @document.version
      @document.contributors << @current_user

      prepare_and_save_to_zoom(@document)

      flash[:notice] = 'Document was successfully updated.'
      redirect_to :action => 'show', :id => @document
    else
      render :action => 'edit'
    end
  end

  def destroy
    zoom_destroy_and_redirect('Document')
  end
end
