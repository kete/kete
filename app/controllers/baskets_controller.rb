class BasketsController < ApplicationController
  ### TinyMCE WYSIWYG editor stuff
  uses_tiny_mce :options => DEFAULT_TINYMCE_SETTINGS,
                :only => VALID_TINYMCE_ACTIONS
  ### end TinyMCE WYSIWYG editor stuff

  permit "site_admin or admin of :current_basket", :only => [:edit, :update, :homepage_options, :destroy,
                                                             :add_index_topic, :appearance, :update_appearance,
                                                             :set_settings]

  before_filter :redirect_if_current_user_cant_add_or_request_basket, :only => [:new, :create]

  after_filter :remove_robots_txt_cache, :only => [:create, :update, :destroy]

  # Get the Privacy Controls helper for the add item forms
  helper :privacy_controls

  include EmailController

  include WorkerControllerHelpers

  include ActionView::Helpers::SanitizeHelper

  # Kieran Pilkington, 2008/11/26
  # Instantiation of Google Map code for location settings
  include GoogleMap::Mapper

  include TaggingController

  def index
    redirect_to :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    list_baskets

    @rss_tag_auto = rss_tag(:replace_page_with_rss => true)
    @rss_tag_link = rss_tag(:replace_page_with_rss => true, :auto_detect => false)

    @requested_count = Basket.count(:conditions => "status = 'requested'")
    @rejected_count = Basket.count(:conditions => "status = 'rejected'")
  end

  def rss
    @number_per_page = 100
    @cache_key_hash = { :rss => "basket_list" }
    unless has_all_rss_fragments?(@cache_key_hash)
      @baskets = Basket.all(:limit => @number_per_page, :order => 'id DESC')
    end
    respond_to do |format|
      format.xml
    end
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
      limit = !feed.limit.nil? ? feed.limit.to_s : ''
      frequency = !feed.update_frequency.nil? ? feed.update_frequency.to_s.gsub('.0', '') : ''
      @feeds_list << "#{feed.title}|#{feed.url}|#{limit}|#{frequency}"
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

    # Because we dont edit the basket content on edit form, skip sanitizing the content
    # to prevent changes in edit from being locked out
    params[:basket][:do_not_sanitize] = true if params[:source_form] == 'edit'

    @feeds_successful = true
    # it is important this is not nil, rather than not blank
    # empty feeds_url_list may mean to delete all existing feeds
    if !params[:feeds_url_list].nil?
      # clear out existing feeds
      # and their workers
      # we will recreate them below if they are to be kept
      @basket.feeds.each do |feed|
        delete_existing_workers_for(:feeds_worker, feed.to_worker_key)
        feed.destroy
      end

      begin
        new_feeds = Array.new
        params[:feeds_url_list].split("\n").each do |feed|
          feed_parts = feed.split('|')
          feed_url = feed_parts[1].strip.gsub("feed:", "http:")
          new_feeds << Feed.create({ :title => feed_parts[0].strip,
                                     :url => feed_url,
                                     :limit => feed_parts[2],
                                     :update_frequency => (feed_parts[3] || 1),
                                     :basket_id => @basket.id })
        end
        @basket.feeds = new_feeds if new_feeds.size > 0
      rescue
        # if there is a problem adding feeds, raise an error the user
        # chances are that they didn't format things correctly
        @basket.errors.add('Feeds', "there was a problem adding your feeds. Is the format you entered correct and you haven\'t entered a feed twice?")
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
      @basket.feeds.each do |feed|
        feed.update_feed
        MiddleMan.new_worker( :worker => :feeds_worker, :worker_key => feed.to_worker_key, :data => feed.id )
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

  def appearance
    appropriate_basket
  end

  def update_appearance
    @basket = Basket.find(params[:id])
    do_not_sanitize = (params[:settings][:do_not_sanitize_footer_content] == 'true')
    original_html = params[:settings][:additional_footer_content]
    sanitized_html = original_html
    unless do_not_sanitize && @site_admin
      sanitized_html = sanitize(original_html)
      params[:settings][:additional_footer_content] = sanitized_html
    end
    set_settings
    flash[:notice] = 'Basket appearance was updated.'
    logger.debug("sanitized yes") if original_html != sanitized_html
    flash[:notice] += ' Your submitted footer content was changed for security reasons.' if original_html != sanitized_html
    redirect_to :action => :appearance
  end

  def choose_type
    # give the user the option to add the item to any place the have access to
    @basket_list = Array.new
    if @site_admin
      @basket_list = Basket.all(:select => 'name,urlified_name').collect { |basket| [basket.name, basket.urlified_name] }
    else
      all_baskets_hash = Hash.new
      Basket.all.each { |b| all_baskets_hash[b.urlified_name.to_sym] = { :basket => b, :privacy => b.settings[:show_add_links] } }
      @basket_list = @basket_access_hash.collect do |basket_urlified_name, basket_hash|
        current_user_is?(all_baskets_hash[basket_urlified_name.to_sym][:privacy], all_baskets_hash[basket_urlified_name.to_sym][:basket]) \
          ? [basket_hash[:basket_name], basket_urlified_name.to_s] \
          : nil
      end.compact
    end

    @item_types = Array.new
    ZOOM_CLASSES.each { |zoom_class| @item_types << [zoom_class_humanize(zoom_class),
                                                     zoom_class_controller(zoom_class)] if zoom_class != 'Comment' }

    return unless request.post?

    redirect_to :urlified_name => params[:new_item_basket],
                :controller => params[:new_item_controller],
                :action => 'new',
                :relate_to_topic => params[:relate_to_topic],
                :related_topic_private => params[:related_topic_private]
  end

  def render_item_form
    @new_item_basket = params[:new_item_basket]
    @new_item_controller = params[:new_item_controller]
    @relate_to_topic = params[:relate_to_topic]
    @related_topic_private = params[:related_topic_private]
    params[:topic] = Hash.new
    params[:topic][:topic_type_id] = params[:new_item_topic_type]

    @item_class = zoom_class_from_controller(@new_item_controller)
    @item = @item_class.constantize.new
    @content_type = ContentType.find_by_class_name(@item_class)

    respond_to do |format|
      format.html { render :partial => 'topics/form', :layout => 'application' }
      format.js do
        render :update do |page|
          page.replace_html 'item_form', :partial => 'topics/form'
          page << "#{raw_tiny_mce_init}"
          page << "tinyMCE.execCommand('mceRemoveControl', false, 'mceEditor');"
          page << "tinyMCE.execCommand('mceAddControl', false, 'mceEditor');"
          page << google_map_initializers if defined?(google_map_initializers)
        end
      end
    end
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
    params[:id].blank? || @current_basket.id == params[:id]
  end

  private

  def list_baskets(per_page=10)
    if !params[:type].blank? && @site_admin
      @listing_type = params[:type]
    else
      @listing_type = 'approved'
    end

    @default_sorting = {:order => 'created_at', :direction => 'desc'}
    paginate_order = current_sorting_options(@default_sorting[:order], @default_sorting[:direction], ['name', 'created_at'])

    options = { :page => params[:page],
                :per_page => per_page,
                :order => paginate_order }
    options.merge!({ :conditions => ['status = ?', @listing_type] })

    @baskets = Basket.paginate(options)
  end

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
