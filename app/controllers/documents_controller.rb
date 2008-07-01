class DocumentsController < ApplicationController
  include ExtendedContentController
  
  helper :privacy_controls
  
  def index
    redirect_to_search_for('Document')
  end

  def list
    index
  end
  
  # James Stradling <james@katipo.co.nz>
  # Show either the public or private version depending on permissions
  def show
    
    # The document has a private version and the correct permissions are set, show that version.
    if logged_in? && permitted_to_view_private_items?

      @document = @current_basket.documents.find(params[:id])
      @document = @document.private_version! if @document.has_private_version? && params[:private] == "true"
      
      # Show the privacy chooser
      @show_privacy_chooser = true
      
    # Otherwise find the document unless it's cached already
    elsif !has_all_fragments? or params[:format] == 'xml'
      @document = @current_basket.documents.find(params[:id])
    end

    @title = @document.title
    
    if !has_fragment?({:part => 'contributions' }) or params[:format] == 'xml'
      @creator = @document.creator
      @last_contributor = @document.contributors.last || @creator
    end

    if @document.private? or !has_fragment?({:part => 'comments' }) or !has_fragment?({:part => 'comments-moderators' }) or params[:format] == 'xml'
      @comments = @document.non_pending_comments
    end

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @document) }
    end
  end
  
  def new
    @document = Document.new({ :private => @current_basket.private_default || false, 
                               :file_private => @current_basket.file_private_default || false })
  end

  def create
    @document = Document.new(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'document', :item_class => 'Document'))
    @successful = @document.save

    # add this to the user's empire of creations
    # TODO: allow current_user whom is at least moderator to pick another user
    # as creator
    if @successful
      @document.creator = current_user

      @document.do_notifications_if_pending(1, current_user)
    end
    
    setup_related_topic_and_zoom_and_redirect(@document, nil, :private => (params[:document][:private] == "true"))
  end

  def edit
    @document = Document.find(params[:id])
    public_or_private_version_of(@document)
  end

  def update
    @document = Document.find(params[:id])

    if @document.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'document', :item_class => 'Document'))

      after_successful_zoom_item_update(@document)

      @document.do_notifications_if_pending(@document.max_version, current_user)

      flash[:notice] = 'Document was successfully updated.'

      redirect_to_show_for(@document, :private => (params[:document][:private] == "true"))
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

  def make_theme
    @document = Document.find(params[:id])
    @document.decompress_as_theme
    flash[:notice] = 'Document expanded to be new theme.'
    redirect_to :action => :appearance, :controller => 'baskets'
  end

  def destroy
    zoom_destroy_and_redirect('Document')
  end
  
end
