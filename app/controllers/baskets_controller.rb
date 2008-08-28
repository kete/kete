class BasketsController < ApplicationController
  ### TinyMCE WYSIWYG editor stuff
  uses_tiny_mce(:options => { :theme => 'advanced',
                  :mode => "textareas",
                  :convert_urls => false,
                  :content_css => "/stylesheets/base.css",
                  :remove_script_host => true,
                  :theme_advanced_toolbar_location => "top",
                  :theme_advanced_toolbar_align => "left",
                  :theme_advanced_resizing => true,
                  :theme_advanced_resize_horizontal => false,
                  :theme_advanced_buttons1 => %w{ bold italic underline strikethrough separator justifyleft justifycenter justifyright indent outdent separator bullist numlist forecolor backcolor separator link unlink image undo redo code},
                  :theme_advanced_buttons2 => %w{ formatselect fontselect fontsizeselect pastetext pasteword selectall },
                  :theme_advanced_buttons3_add => %w{ tablecontrols fullscreen},
                  :editor_selector => 'mceEditor',
                  :paste_create_paragraphs => true,
                  :paste_create_linebreaks => true,
                  :paste_use_dialog => true,
                  :paste_auto_cleanup_on_paste => true,
                  :paste_convert_middot_lists => false,
                  :paste_unindented_list_class => "unindentedList",
                  :paste_convert_headers_to_strong => true,
                  :paste_insert_word_content_callback => "convertWord",
                  :plugins => %w{ contextmenu paste table fullscreen} },
                :only => [:new, :pick, :create, :edit, :update, :homepage_options])
  ### end TinyMCE WYSIWYG editor stuff

  after_filter :repopulate_basket_permissions, :only => [:create, :destroy]

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @baskets = Basket.paginate(:page => params[:page],
                               :per_page => 10)
  end

  def show
    redirect_to_default_all
  end

  def new
    @basket = Basket.new
  end

  def create
    @basket = Basket.new(params[:basket])

    convert_text_fields_to_boolean

    if @basket.save
      set_settings

      @basket.accepts_role('admin', current_user)

      flash[:notice] = 'Basket was successfully created.'
      redirect_to :urlified_name => @basket.urlified_name, :controller => 'baskets', :action => 'edit', :id => @basket
    else
      render :action => 'new'
    end
  end

  def edit
    appropriate_basket
    @topics = @basket.topics
    @index_topic = @basket.index_topic
  end

  def homepage_options
    edit
  end

  def update
    params[:source_form] ||= 'edit'
    @basket = Basket.find(params[:id])
    @topics = @basket.topics
    original_name = @basket.name

    # have to update zoom records for things in the basket
    # in two steps
    # delete old record before basket.urlified_name has changed
    # as well as caches
    # because item.zoom_destroy needs original record to match
    # then after update, create new zoom records with new urlified_name
    if !params[:basket][:name].blank? and original_name != params[:basket][:name]
      ZOOM_CLASSES.each do |zoom_class|
        basket_items = @basket.send(zoom_class.tableize)
        basket_items.each do |item|
          expire_show_caches_for(item)
          zoom_destroy_for(item)
        end
      end
    end

    convert_text_fields_to_boolean

    if @basket.update_attributes(params[:basket])
      # Reload to ensure basket.name is updated and not the previous
      # basket name.
      @basket.reload

      set_settings

      # clear slideshow in session
      # in case the user user changes how images should be ordered
      session[:slideshow] = nil

      # @basket.name has changed
      if original_name != @basket.name
        # update zoom records for basket items
        # to match new basket.urlified_name
        ZOOM_CLASSES.each do |zoom_class|
          basket_items = @basket.send(zoom_class.tableize)
          basket_items.each do |item|
            prepare_and_save_to_zoom(item)
          end
        end
      end
      flash[:notice] = 'Basket was successfully updated.'
      redirect_to "/#{@basket.urlified_name}/"
    else
      render :action => params[:source_form]
    end
  end

  def destroy
    @basket = Basket.find(params[:id])

    # dependent destroy isn't sufficient
    # to delete zoom items from the zoom_db
    # has to be done in the controller
    # because of the reliance on preparing the zoom record
    ZOOM_CLASSES.each do |zoom_class|
      # skip comments, they should be destroyed by their parent items
      if zoom_class != 'Comment'
        zoom_items = @basket.send(zoom_class.tableize)
        if zoom_items.size > 0
          zoom_items.each do |item|
            @successful = zoom_item_destroy(item)
            if !@successful
              break
            end
          end
        else
          @successful = true
        end
      end
      if !@successful
        break
      end
    end

    if @successful
      @successful = @basket.destroy
    end

    if @successful
      flash[:notice] = 'Basket was successfully deleted.'
      redirect_to '/'
    end
  end

  def add_index_topic
    @topic = Topic.find(params[:topic])
    @successful = Basket.find(params[:index_for_basket]).update_index_topic(@topic)
    if @successful
      # this action saves a new version of the topic
      # add this as a contribution
      @topic.add_as_contributor(current_user)
      flash[:notice] = 'Basket homepage was successfully created.'
      redirect_to :action => 'homepage_options', :controller => 'baskets', :id => params[:index_for_basket]
    end
  end

  def link_index_topic
    @topic = Topic.find(params[:topic])
    @successful = Basket.find(params[:index_for_basket]).update_index_topic(@topic)
    if @successful
      # this action saves a new version of the topic
      # add this as a contribution
      @topic.add_as_contributor(current_user)
      render :text => 'Basket homepage was successfully chosen.  Please close this window. Clicking on another topic will replace this topic with the new topic clicked.'
    end
  end

  def appearance
    appropriate_basket
  end

  def update_appearance
    @basket = Basket.find(params[:id])
    set_settings
    flash[:notice] = 'Basket appearance was updated.'
    redirect_to :action => :appearance
  end

  def choose_type
    return unless request.post?
    redirect_to :controller => params[:new_controller], :action => 'new'
  end

  # the start of a page
  # where the user is told they don't have access to requested action
  # and they are presented with options to continue
  # in the future this will present the join policy of the basket, etc
  # now it only says "login as different user or contact an administrator"
  def permissioned_denied
    session[:has_access_on_baskets] = logged_in? ? current_user.get_basket_permissions : Hash.new
  end

  def set_settings
    if !params[:settings].nil?
      params[:settings].each do |name, value|
        # HACK
        # is there a better way to typecast?
        # rails does so in AR, but not sure it's appropriate here
        case value
        when "true"
          value = true
        when "false"
          value = false
        when "nil"
          value = nil
        end
        @basket.settings[name] = value
      end
    end
  end

  def appropriate_basket
    @basket = current_basket_is_selected? ? @current_basket : Basket.find(params[:id])
  end

  def current_basket_is_selected?
    params[:id].blank? or @current_basket.id == params[:id]
  end

  private

  # Kieran Pilkington, 2008/08/26
  # In order to set settings back to inherit, we have to take strings
  # and convert back to booleans or nil later. We have to take boolean
  # as well though, as they are used in functional tests
  def convert_text_fields_to_boolean
    boolean_fields = [:show_privacy_controls, :private_default, :file_private_default, :allow_non_member_comments]
    boolean_fields.each do |field|
      params[:basket][field] = case params[:basket][field]
      when 'true', true
        true
      when 'false', false
        false
      else
        nil
      end
    end
  end

  def repopulate_basket_permissions
    session[:has_access_on_baskets] = current_user.get_basket_permissions
  end

end
