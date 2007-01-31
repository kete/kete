class DocumentsController < ApplicationController
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def index
    redirect_to_search_for('Document')
  end

  def list
    index
  end

  def show
    @document = @current_basket.documents.find(params[:id])
    @title = @document.title
    @creator = @document.creators.first
    @last_contributor = @document.contributors.last || @creator

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
    @document.creators << current_user

    setup_related_topic_and_zoom_and_redirect(@document)
  end

  def edit
    @document = Document.find(params[:id])
  end

  def update
    @document = Document.find(params[:id])

    if @document.update_attributes(params[:document])
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
