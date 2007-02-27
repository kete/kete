class DocumentsController < ApplicationController
  include ExtendedContentController

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  ### TinyMCE WYSIWYG editor stuff
  uses_tiny_mce(:options => { :theme => 'advanced',
                  :browsers => %w{ msie gecko safari},
                  :mode => "textareas",
                  :theme_advanced_toolbar_location => "top",
                  :theme_advanced_toolbar_align => "left",
                  :theme_advanced_resizing => true,
                  :theme_advanced_resize_horizontal => false,
                  :paste_auto_cleanup_on_paste => true,
                  :theme_advanced_buttons1 => %w{ bold italic underline strikethrough separator justifyleft justifycenter justifyright indent outdent separator bullist numlist forecolor backcolor separator link unlink image undo redo},
                  :theme_advanced_buttons2 => %w{ formatselect fontselect fontsizeselect},
                  :theme_advanced_buttons3 => [],
                  :theme_advanced_buttons3_add => %w{ tablecontrols fullscreen},
                  :editor_selector => 'mceEditor',
                  :plugins => %w{ contextmenu paste table fullscreen} },
                :only => [:new, :create, :edit, :update])
  ### end TinyMCE WYSIWYG editor stuff

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
    @document = Document.new(extended_fields_and_params_hash_prepare(:content_type => @content_type, :item_key => 'document', :item_class => 'Document'))
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

  private
  def load_content_type
    @content_type = ContentType.find_by_class_name('Document')
  end
end
