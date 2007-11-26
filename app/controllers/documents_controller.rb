class DocumentsController < ApplicationController
  include ExtendedContentController

  # other actions that need caches expired are handled in application.rb
  before_filter :expire_show_caches, :only => [ :convert ]

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

      after_successful_zoom_item_update(@document)

      flash[:notice] = 'Document was successfully updated.'

      redirect_to_show_for(@document)
    else
      render :action => 'edit'
    end
  end

  # converts uploaded document to document description in html form
  def convert
    @document = Document.find(params[:id])
    if @document.do_conversion
      after_successful_zoom_item_update(@document)
      flash[:notice] = 'Document description was successfully updated with text of uploaded document.'
    else
      flash[:notice] = 'There were problems converting the text of the uploaded document to the document\'s description.  Please edit the description manually.'
    end
    redirect_to_show_for(@document)
  end

  def destroy
    zoom_destroy_and_redirect('Document')
  end
end
