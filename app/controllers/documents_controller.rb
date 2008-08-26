class DocumentsController < ApplicationController
  include ExtendedContentController

  helper :privacy_controls

  def index
    redirect_to_search_for('Document')
  end

  def list
    index
  end

  def show
    prepare_item_variables_for("Document", true)
    @document = @item

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

    version_after_update = @document.max_version + 1

    if @document.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'document', :item_class => 'Document'))

      after_successful_zoom_item_update(@document)

      @document.do_notifications_if_pending(version_after_update, current_user) if
        @document.versions.exists?(:version => version_after_update)

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
