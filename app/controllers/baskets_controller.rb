class BasketsController < ApplicationController
  ### TinyMCE WYSIWYG editor stuff
  uses_tiny_mce :options => DEFAULT_TINYMCE_SETTINGS,
                :only => VALID_TINYMCE_ACTIONS
  ### end TinyMCE WYSIWYG editor stuff

  permit "site_admin or admin of :current_basket", :except => [:index, :list, :show, :new, :create, :choose_type,
                                                               :permission_denied, :contact, :send_email]

  before_filter :redirect_if_current_user_cant_add_or_request_basket, :only => [:new, :create]

  after_filter :remove_robots_txt_cache, :only => [:create, :update, :destroy]

  include EmailController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    if !params[:type].blank? && @site_admin
      @listing_type = params[:type]
    else
      @listing_type = 'approved'
    end

    paginate_order = current_sorting_options('name', 'asc', ['name', 'created_at'])

    options = { :page => params[:page],
                :per_page => 5,
                :order => paginate_order }
    options.merge!({ :conditions => ['status = ?', @listing_type] })

    @baskets = Basket.paginate(options)

    @requested_count = Basket.count(:conditions => "status = 'requested'")
    @rejected_count = Basket.count(:conditions => "status = 'rejected'")
  end

  def show
    redirect_to_default_all
  end

  def new
    @basket = Basket.new
  end

  def create
    convert_text_fields_to_boolean

    # if an site admin makes a basket, make sure the basket is instantly approved
    if basket_policy_request_with_permissions?
      params[:basket][:status] = 'requested'
    else
      params[:basket][:status] = 'approved'
    end

    params[:basket][:creator_id] = current_user.id

    @basket = Basket.new(params[:basket])

    if @basket.save
      # Reload to ensure basket.creator is updated.
      @basket.reload

      set_settings

      # if basket creator is admin or creation not moderated, make creator basket admin
      @basket.accepts_role('admin', current_user) if BASKET_CREATION_POLICY == 'open' || @site_admin

      # if an site admin makes a basket, make sure emailing notifications are skipped
      if basket_policy_request_with_permissions?
        @site_basket.administrators.each do |administrator|
          UserNotifier.deliver_basket_notification_to(administrator, current_user, @basket, 'request')
        end
        flash[:notice] = 'Basket will now be reviewed, and you\'ll be notified of the outcome.'
        redirect_to "/#{@site_basket.urlified_name}"
      else
        if !@site_admin
          @site_basket.administrators.each do |administrator|
            UserNotifier.deliver_basket_notification_to(administrator, current_user, @basket, 'created')
          end
        end
        flash[:notice] = 'Basket was successfully created.'
        redirect_to :urlified_name => @basket.urlified_name, :controller => 'baskets', :action => 'edit', :id => @basket
      end
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

    @feeds_list = []
    @basket.feeds.each do |feed|
      limit = !feed.limit.nil? ? "|#{feed.limit.to_s}" : ''
      @feeds_list << "#{feed.title}|#{feed.url}#{limit}"
    end
    @feeds_list = @feeds_list.join("\n")
  end

  def update
    params[:source_form] ||= 'edit'
    @basket = Basket.find(params[:id])
    @topics = @basket.topics
    original_name = @basket.name

    unless params[:accept_basket].blank?
      params[:basket][:status] = 'approved'
      @basket.accepts_role('admin', @basket.creator)
    end

    unless params[:reject_basket].blank?
      params[:basket][:status] = 'rejected'
    end

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

    if !params[:feeds_url_list].nil?
      # we call destroy_all here instead of delete_all so that callbacks are triggered
      @basket.feeds.destroy_all

      @feeds_successful = true
      begin
        new_feeds = Array.new
        params[:feeds_url_list].split("\n").each do |feed|
          feed_parts = feed.split('|')
          feed_url = feed_parts[1].strip.gsub("feed:", "http:")
          new_feeds << Feed.create({ :title => feed_parts[0].strip,
                                     :url => feed_url,
                                     :limit => (feed_parts[2] || nil),
                                     :basket_id => @basket.id })
        end
        @basket.feeds = new_feeds if new_feeds.size > 0
      rescue
        # if there is a problem adding feeds, raise an error the user
        # chances are that they didn't format things correctly
        @basket.errors.add('Feeds', "there was a problem adding your feeds. Is the format you entered correct and you havn't entered a feed twice?")
        @feeds_successful = false
      end
    end

    convert_text_fields_to_boolean if params[:source_form] == 'edit'

    if @feeds_successful && @basket.update_attributes(params[:basket])
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

      # We send the emails right before a redirect so
      # it doesn't break anything if the emailing fails
      unless params[:accept_basket].blank?
        UserNotifier.deliver_basket_notification_to(@basket.creator, current_user, @basket, 'approved')
      end
      unless params[:reject_basket].blank?
        UserNotifier.deliver_basket_notification_to(@basket.creator, current_user, @basket, 'rejected')
      end

      # Add this last because it takes the longest time to process
      @basket.feeds.each { |feed| feed.update_feed }

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
  def permission_denied
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

  # Kieran Pilkington, 2008/10/01
  # When a basket is created, edited, or deleted, we have to clear
  # the robots txt file caches to the new settings take effect
  def remove_robots_txt_cache
    expire_page "/robots.txt"
  end

  # Kieran Pilkington - 2008/09/22
  # redirect to permission denied if current user cant add/request baskets
  def redirect_if_current_user_cant_add_or_request_basket
    unless current_user_can_add_or_request_basket?
      flash[:error] = "You need to have the right permissions to add or request a basket"
      redirect_to DEFAULT_REDIRECTION_HASH
    end
  end

end
