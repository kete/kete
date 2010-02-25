class DocumentsController < ApplicationController
  include ExtendedContentController

  def index
    redirect_to_search_for('Document')
  end

  def list
    index
  end

  def show
    @document = prepare_item_and_vars

    respond_to do |format|
      format.html
      format.xml { render_oai_record_xml(:item => @document) }
    end
  end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(params[:document])
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

    @successful = ensure_no_new_insecure_elements_in('document')
    @document.attributes = params[:document]
    @successful = @document.save if @successful

    if @successful

      after_successful_zoom_item_update(@document, version_after_update)
      flash[:notice] = t('documents_controller.update.updated')

      redirect_to_show_for(@document, :private => (params[:document][:private] == "true"))
    else
      render :action => 'edit'
    end
  end

  # converts uploaded document to document description in html form
  def convert
    @document = Document.find(params[:id])
    public_or_private_version_of(@document)
    version_after_update = @document.max_version + 1
    error_msg = t('documents_controller.convert.not_converted')
    if @document.do_conversion
      after_successful_zoom_item_update(@document, version_after_update)
      flash[:notice] = t('documents_controller.convert.converted')
    else
      flash[:error] = error_msg
    end
    redirect_to_show_for(@document, :private => (params[:private] == "true"))
  end

  def make_theme
    @document = Document.find(params[:id])
    @document.decompress_as_theme
    flash[:notice] = t('documents_controller.make_theme.made_theme')
    redirect_to :action => :appearance, :controller => 'baskets'
  end

  def destroy
    zoom_destroy_and_redirect('Document')
  end

end
