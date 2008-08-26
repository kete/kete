# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base

  # See lib/ssl_helpers.rb
  include SslHelpers

  include AuthenticatedSystem

  include ZoomControllerHelpers

  include ExtendedFieldsControllerHelpers

  include FriendlyUrls

  # for the remember me functionality
  before_filter :login_from_cookie

  # only permit site members to add/delete things
  before_filter :login_required, :only => [ :new, :pick_topic_type, :create,
                                            :edit, :update, :destroy,
                                            :appearance, :homepage_options,
                                            :convert,
                                            :make_theme,
                                            :find_related,
                                            :link_related,
                                            :link_index_topic,
                                            :flag_form,
                                            :flag_version,
                                            :restore,
                                            :reject,
                                            :choose_type,
                                            :setup_rebuild,
                                            :rebuild_zoom_index]

  # all topics and content items belong in a basket
  # and will always be specified in our routes
  before_filter :load_standard_baskets

  before_filter :load_theme_related

  # sets up instance variables for authentication
  include KeteAuthorization

  # keep track of tag_list input by version
  before_filter :update_params_with_raw_tag_list, :only => [ :create, :update ]

  # see method definition for details

  before_filter :delete_zoom_record, :only => [ :update, :flag_version, :restore ]

  # we often need baskets for edits
  before_filter :load_array_of_baskets, :only => [ :edit, :update ]

  # only site_admin can set item.do_not_sanitize to true
  before_filter :security_check_of_do_not_sanitize, :only => [ :create, :update ]

  # don't allow forms to set do_not_moderate
  before_filter :security_check_of_do_not_moderate, :only => [ :create, :update, :restore ]

  # set do_not_moderate if site_admin, otherwise things like moving from one basket to another
  # may get tripped up
  before_filter :set_do_not_moderate_if_site_admin, :only => [ :create, :update ]

  # ensure that users who are in a basket where the action menu has been hidden can edit
  # by posting a dummy form
  before_filter :current_user_can_see_action_menu?, :only => [:new, :create, :edit, :update]

  # creates a @cache_id variable based on params[:id]
  before_filter :set_cache_id, :only => [:show]

  # if anything is updated or deleted
  # we need toss our show action fragments
  # destroy has to happen before the item is deleted
  before_filter :expire_show_caches, :only => [ :destroy ]
  # everything else we do after the action is completed
  after_filter :expire_show_caches, :only => [ :update, :convert ]

  # setup return_to for the session
  # TODO: this needs to be updated to store location for newer actions
  # might be better to do an except?
  after_filter :store_location, :only => [ :for, :all, :search, :index, :new, :show, :edit, :new_related_set_from_archive_file]

  # if anything is added, edited, or deleted
  # we need to rebuild our rss caches
  after_filter :expire_rss_caches, :only => [ :create, :update, :destroy]

  # if anything is added, edited, or deleted in a basket
  # we need toss our basket index page fragments
  after_filter :expire_basket_index_caches, :only => [ :create,
                                                       :update,
                                                       :destroy,
                                                       :add_index_topic, :link_index_topic]

  helper :slideshows

  def set_cache_id
    @cache_id = params[:id] ? params[:id].to_i : nil
  end

  # set the current basket to the default
  # unless we have urlified_name that is different
  # than the default
  # TODO: cache in memcache
  def load_standard_baskets
    # could DRY this up with one query for all the baskets
    @site_basket ||= Basket.site_basket
    @help_basket ||= Basket.help_basket
    @about_basket ||= Basket.about_basket
    @documentation_basket ||= Basket.documentation_basket
    @standard_baskets ||= Basket.standard_baskets

    if params[:urlified_name].blank?
      @current_basket = @site_basket
    else
      case params[:urlified_name]
      when @site_basket.urlified_name
        @current_basket = @site_basket
      when @about_basket.urlified_name
        @current_basket = @about_basket
      when @help_basket.urlified_name
        @current_basket = @help_basket
      when @documentation_basket.urlified_name
        @current_basket = @documentation_basket
      else
        @current_basket = Basket.find_by_urlified_name(params[:urlified_name])
      end
    end
    if @current_basket.nil?
      @current_basket = @site_basket
      load_theme_related
      raise ActiveRecord::RecordNotFound, "Couldn't find Basket with NAME=#{params[:urlified_name]}."
    end
  end

  # figure out which theme we need
  # and load up an array of the web paths
  # to the css files
  def load_theme_related
    @theme = @current_basket.settings[:theme] || @site_basket.settings[:theme] || 'default'
    @theme_font_family = @current_basket.settings[:theme_font_family] || @site_basket.settings[:theme_font_family] || 'sans-serif'
    @header_image = @current_basket.settings[:header_image] || @site_basket.settings[:header_image] || nil
  end

  def security_check_of_do_not_sanitize
    item_class = zoom_class_from_controller(params[:controller])
    item_class_for_param_key = item_class.tableize.singularize
    if ZOOM_CLASSES.include?(item_class) && !params[item_class_for_param_key].nil? && !params[item_class_for_param_key][:do_not_sanitize].nil?
      params[item_class_for_param_key][:do_not_sanitize] = false if !@site_admin
    end
  end

  def security_check_of_do_not_moderate
    item_class = zoom_class_from_controller(params[:controller])
    item_class_for_param_key = item_class.tableize.singularize
    if ZOOM_CLASSES.include?(item_class) && !params[item_class_for_param_key].nil? && !params[item_class_for_param_key][:do_not_moderate].nil?
      params[item_class_for_param_key][:do_not_moderate] = false if !@site_admin
    end
  end

  def current_user_can_see_flagging?
    current_user_is?(@current_basket.settings[:show_flagging])
  end

  def current_user_can_see_add_links?
    current_user_is?(@current_basket.settings[:show_add_links])
  end

  def current_user_can_see_action_menu?
    current_user_is?(@current_basket.settings[:show_action_menu])
  end

  def current_user_can_see_discussion?
    current_user_is?(@current_basket.settings[:show_discussion])
  end

  # Specific test for private file visibility.
  def current_user_can_see_private_files_for?(item)
    current_user_can_see_private_files_in_basket?(item.basket)
  end

  # Test for private file visibility in a given basket
  def current_user_can_see_private_files_in_basket?(basket)
    current_user_is?(basket.private_file_visibility)
  end

  # Walter McGinnis, 2006-04-03
  # bug fix for when site admin moves an item from one basket to another
  # if params[:topic][basket_id] exists and site admin
  # set do_not_moderate to true
  def set_do_not_moderate_if_site_admin
    item_class = zoom_class_from_controller(params[:controller])
    item_class_for_param_key = item_class.tableize.singularize
    if ZOOM_CLASSES.include?(item_class)
      if !params[item_class_for_param_key].nil? && @site_admin
        params[item_class_for_param_key][:do_not_moderate] = true
      elsif !params[item_class_for_param_key].nil? && !params[item_class_for_param_key][:do_not_moderate].nil?
        params[item_class_for_param_key][:do_not_moderate] = false
      end
    end
  end

  def item_from_controller_and_id
    Module.class_eval(zoom_class_from_controller(params[:controller])).find(params[:id])
  end

  # some updates will change the item so that the updating of zoom record
  # will no longer match the existing record
  # and create a new one instead
  # so we delete the existing zoom record here
  # and create a new zoom record in the update
  def delete_zoom_record
    zoom_class = zoom_class_from_controller(params[:controller])
    if ZOOM_CLASSES.include?(zoom_class)
      zoom_destroy_for(Module.class_eval(zoom_class).find(params[:id]))
    end
  end

  # so we can transfer an item from one basket to another
  def load_array_of_baskets
    zoom_class = zoom_class_from_controller(params[:controller])
    if ZOOM_CLASSES.include?(zoom_class) and zoom_class != 'Comment'
      @baskets = Basket.find(:all, :order => 'name').map { |basket| [ basket.name, basket.id ] }
    end
  end

  # caching related
  SHOW_PARTS = ['page_title_[privacy]', 'edit_[privacy]', 'history', 'details_first_[privacy]', 'details_second_[privacy]', 'contributor_[privacy]', 'flagging_[privacy]', 'secondary_content_tags_[privacy]', 'secondary_content_extended_fields_[privacy]']
  PUBLIC_SHOW_PARTS = ['comments_[privacy]']
  MODERATOR_SHOW_PARTS = ['delete', 'comments-moderators_[privacy]']
  ADMIN_SHOW_PARTS = ['zoom_reindex']
  PRIVACY_SHOW_PARTS = ['privacy_chooser_[privacy]']

  INDEX_PARTS = [ 'details', 'edit', 'recent_topics', 'search', 'extra_side_bar_html', 'archives', 'tags']

  # the following method is used when clearing show caches
  def all_show_parts
    SHOW_PARTS + PUBLIC_SHOW_PARTS + MODERATOR_SHOW_PARTS + ADMIN_SHOW_PARTS + PRIVACY_SHOW_PARTS
  end

  # the following method is used when seeing if all fragments are present
  # for example, we dont want to stop optimization if an admin fragment is missing for a logged out user
  def relevant_show_parts
    show_parts = SHOW_PARTS
    if logged_in? and @at_least_a_moderator
      show_parts += MODERATOR_SHOW_PARTS
    else
      show_parts += PUBLIC_SHOW_PARTS
    end
    if logged_in? and @site_admin
      show_parts += ADMIN_SHOW_PARTS
    end
    if @show_privacy_chooser
      show_parts += PRIVACY_SHOW_PARTS
    end
    show_parts
  end

  # if anything is added, edited, or destroyed in a basket
  # expire the basket index page caches
  def expire_basket_index_caches
    # we always expire the site basket index page, too
    # since items added, edited, or destroyed from any basket
    # show up in the contents list, as well as most recent topics, etc.
    baskets_to_expire = [@current_basket, @site_basket]
    INDEX_PARTS.each do |part|
      baskets_to_expire.each do |basket|
        expire_fragment(:controller => 'index_page',
                        :action => 'index',
                        :urlified_name => basket.urlified_name,
                        :part => part)
      end
    end
  end

  def expire_fragment_for_all_versions(item, name = {})

    name = name.merge(:id => item.id)
    file_path = "#{RAILS_ROOT}/tmp/cache/#{fragment_cache_key(name).gsub("?", ".") + '.cache'}"
    if File.exists?(file_path)
      File.delete(file_path)
    end

    # Kieran Pilkington, 2008-08-05
    # we dont need to remove history caches, they dont change, only the live versions do
    # (from what I can see anyway)

    # slight change for postgresql
    # this works with mysql and postgresql, not sure about sqlite or oracle
    #item.versions.find(:all, :select => 'distinct title, version').each do |version|
    #  expire_fragment(name.merge(:id => item.id.to_s + format_friendly_for(version.title)))
    #end
  end

  # expire the cache fragments for the show action
  # excluding the related cache, this we handle separately
  def expire_show_caches
    caches_controllers = ['audio', 'baskets', 'comments', 'documents', 'images', 'topics', 'video', 'web_links']
    if caches_controllers.include?(params[:controller])
      # James - 2008-07-01
      # Ensure caches are expired in the context of privacy.
      item = item_from_controller_and_id
      item.private_version! if item.respond_to?(:private) && item.latest_version_is_private?

      expire_show_caches_for(item)
    end
  end

  def expire_show_caches_for(item)
    # only do this for zoom_classes
    item_class = item.class.name
    controller = zoom_class_controller(item_class)
    return unless ZOOM_CLASSES.include?(item_class)

    all_show_parts.each do |part|

      # James - 2008-07-01
      # Some cache keys have a privacy scope, indicated by [privacy] in the key name.
      # In these cases, replace this with the actual item's current privacy.
      # I.e. secondary_content_tags_[privacy] => secondary_content_tags_private where
      # the current item is private.

      if part.include?('_[privacy]')
        resulting_part = part.sub(/\[privacy\]/, (item.private? ? "private" : "public"))
      else
        resulting_part = part
      end

      # we have to do this for each distinct title the item previously had
      # because old titles' friendly urls won't be matched in our expiry otherwise
      expire_fragment_for_all_versions(item, { :controller => controller, :action => 'show', :id => item, :part => resulting_part })
    end
    
    # images have an additional cache
    # and topics may also have a basket index page cached
    if controller == 'images'
      expire_fragment_for_all_versions(item, { :controller => controller, :action => 'show', :id => item, :part => ('caption_'+(item.private? ? "private" : "public")) })
    elsif controller == 'topics'
      if item.index_for_basket.is_a?(Basket)
        # slight overkill, but most parts
        # would need to be expired anyway
        expire_fragment(/#{item.index_for_basket.urlified_name}\/index_page\/index\/(.+)/)
      end
    end

    # if we are deleting the thing
    # also delete it's related caches
    # as well as related caches of things it's related to
    if params[:action] == 'destroy'
      if controller != 'topics'
        expire_fragment_for_all_versions(item, { :controller => controller, :action => 'show', :id => item, :related => 'topics' })
        # expire any related topics related caches
        # comments don't have related topics, so skip it for them
        if item_class != 'Comment'
          item.topics.each do |topic|
            expire_related_caches_for(topic, controller)
          end
        end
      else
        # topics need all it's related things expired
        ZOOM_CLASSES.each do |zoom_class|
          expire_fragment_for_all_versions(item, { :action => 'show', :id => item, :related => zoom_class_controller(zoom_class) })
          related_items = Array.new
          if zoom_class == 'Topic'
            related_items += item.related_topics
          else
            related_items += item.send(zoom_class.tableize)
          end
          related_items.each do |related_item|
            expire_related_caches_for(related_item, 'topics')
          end
        end
      end
    end
  end

  def expire_related_caches_for(item, controller = nil)
    related = Array.new
    if !controller.nil?
      related << controller
    else
      if item.class.name != 'Topic'
        related << 'topics'
      else
        # topics need all it's related things expired
        ZOOM_CLASSES.each do |zoom_class|
          related << zoom_class_controller(zoom_class)
        end
      end
    end
    related.each do |related_controller|
      expire_fragment_for_all_versions(item,
                                       { :urlified_name => item.basket.urlified_name,
                                         :controller => zoom_class_controller(item.class.name),
                                         :action => 'show',
                                         :id => item,
                                         :related => related_controller} )
      # we have two more caches for controls for those that are privileged
      ['restore', 'upload_archive'].each do |sub_part|
        expire_fragment_for_all_versions(item,
                                         { :urlified_name => item.basket.urlified_name,
                                           :controller => zoom_class_controller(item.class.name),
                                           :action => 'show',
                                           :id => item,
                                           :related => "#{related_controller}_#{sub_part}" })
      end
    end
  end

  def expire_contributions_caches_for(item)
    # rather than find out if the contribution is for a public/private item
    # just clear both the caches
    ['contributor_public', 'contributor_private'].each do |part|
      expire_fragment_for_all_versions(item,
                                      { :urlified_name => item.basket.urlified_name,
                                        :controller => zoom_class_controller(item.class.name),
                                        :action => 'show',
                                        :id => item,
                                        :part => part })
    end
  end

  def expire_caches_after_comments(item, private_comment)
    ['zoom_reindex', 'comments-moderators_[privacy]', 'comments_[privacy]'].each do |part|

      if part.include?('_[privacy]')
        resulting_part = part.sub(/\[privacy\]/, (private_comment ? "private" : "public"))
      else
        resulting_part = part
      end

      expire_fragment_for_all_versions(item,
                                       { :urlified_name => item.basket.urlified_name,
                                         :controller => zoom_class_controller(item.class.name),
                                         :action => 'show',
                                         :id => item,
                                         :part => resulting_part } )
    end
  end

  # cheating, we know that we are using file store, rather than mem_cache
  # TODO: put an if mem_cache ... use read_fragment({:part => part})
  # wrapped in this method
  def has_fragment?(name = {})
    # strip out everything after id (title in friendly url)
    name[:id] = name[:id].to_i unless name[:id].blank?
    File.exists?("#{RAILS_ROOT}/tmp/cache/#{fragment_cache_key(name).gsub("?", ".") + '.cache'}")
  end

  # used by show actions to determine whether to load item
  def has_all_fragments?
    #logger.info('Looking for all fragments')

    # we are going a bit overboard with the params[:id].to_i bit
    # but we need to be consistent
    name = params[:id].blank? ? Hash.new : { :id => params[:id].to_i }
    if params[:controller] != 'index_page'
      relevant_show_parts.each do |part|
        if part.include?('_[privacy]')
          resulting_part = part.sub(/\[privacy\]/, get_acceptable_privacy_type("public", "private"))
        else
          resulting_part = part
        end
        return false unless has_fragment?(name.merge(:part => resulting_part))
      end
    end
    #logger.info('Has all show fragments')

    case params[:controller]
    when 'index_page'
      INDEX_PARTS.each do |part|
        return false unless has_fragment?({:part => part})
      end
    when 'topics'
      ZOOM_CLASSES.each do |zoom_class|
        if zoom_class != 'Comment'
          return false unless has_fragment?(name.merge(:related => zoom_class_controller(zoom_class)))
        end
      end
    else
      return false unless has_fragment?(name.merge(:related => 'topics'))
    end
    #logger.info('Has all related/index parts')
    return true
  end

  # remove rss feeds under all and search directories
  # for the class of thing that was just added
  def expire_rss_caches(basket = nil)
    # only applicable to zoom classes
    return unless ZOOM_CLASSES.include?(zoom_class_from_controller(params[:controller]))

    basket ||= @current_basket

    if @current_basket.nil?
      load_basket
      basket ||= @current_basket
    end

    # since site searches all other baskets, too
    # we need to expire it's cache, too
    if @current_basket != @site_basket
      expire_page(:controller => 'search', :action => 'rss', :urlified_name => @site_basket.urlified_name, :controller_name_for_zoom_class => params[:controller])
    end

    expire_page(:controller => 'search', :action => 'rss', :urlified_name => basket.urlified_name, :controller_name_for_zoom_class => params[:controller])

  end

  def redirect_to_related_topic(topic_id)
    redirect_to_show_for(Topic.find(topic_id))
  end

  def update_zoom_and_related_caches_for(item, controller = nil)
    # refresh data for the item
    item = Module.class_eval(item.class.name).find(item)

    prepare_and_save_to_zoom(item)

    if controller.nil?
      expire_related_caches_for(item)
    else
      expire_related_caches_for(item, controller)
    end
  end

  def add_relation_and_update_zoom_and_related_caches_for(item, new_related_topic)
    # clear out old zoom records before we change the items
    # sometimes zoom updates are confused and create a duplicate new record
    # instead of updating existing one
    zoom_destroy_for(item)
    zoom_destroy_for(new_related_topic)

    successful = ContentItemRelation.new_relation_to_topic(new_related_topic.id, item)

    update_zoom_and_related_caches_for(new_related_topic, zoom_class_controller(item.class.name))

    return successful
  end

  def remove_relation_and_update_zoom_and_related_caches_for(item, new_related_topic)
    # clear out old zoom records before we change the items
    # sometimes zoom updates are confused and create a duplicate new record
    # instead of updating existing one
    zoom_destroy_for(item)
    zoom_destroy_for(new_related_topic)

    successful = ContentItemRelation.destroy_relation_to_topic(new_related_topic.id, item)

    update_zoom_and_related_caches_for(new_related_topic, zoom_class_controller(item.class.name))

    return successful
  end

  def setup_related_topic_and_zoom_and_redirect(item, commented_item = nil, options = {})
    where_to_redirect = 'show_self'
    if !commented_item.nil? and @successful
      where_to_redirect = 'commentable'
    elsif params[:relate_to_topic] and @successful
      @new_related_topic = Topic.find(params[:relate_to_topic])

      add_relation_and_update_zoom_and_related_caches_for(item, @new_related_topic)

      where_to_redirect = 'show_related'
    elsif params[:is_theme] and item.class.name == 'Document' and @successful
      item.decompress_as_theme
      where_to_redirect = 'appearance'
    end

    if @successful
      update_zoom_and_related_caches_for(item)

      case where_to_redirect
      when 'show_related'
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = "Related #{zoom_class_humanize(item.class.name)} was successfully created."
        redirect_to_related_topic(@new_related_topic)
      when 'commentable'
        redirect_to_show_for(commented_item, options)
      when 'appearance'
        redirect_to :action => :appearance, :controller => 'baskets'
      else
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = "#{zoom_class_humanize(item.class.name)} was successfully created."

        redirect_to_show_for(item, options)
      end
    else
      render :action => 'new'
    end
  end

  def link_related
    @related_to_topic = Topic.find(params[:relate_to_topic])

    unless params[:item].blank?
      for id in params[:item].reject { |k, v| v != "true" }.collect { |k, v| k }
        item = only_valid_zoom_class(params[:related_class]).find(id)

        if params[:related_class] == 'Topic'
          @existing_relation = @related_to_topic.related_topics.include?(item)
        else
          @existing_relation = @related_to_topic.send(params[:related_class].tableize).include?(item)
        end

        if !@existing_relation
          @successful = add_relation_and_update_zoom_and_related_caches_for(item, @related_to_topic)

          if @successful
            # in this context, the item being related needs updating, too
            update_zoom_and_related_caches_for(item)

            flash[:notice] = "Successfully added item relationships"
          end
        end
      end
    end

    redirect_to :controller => 'search', :action => 'find_related', :relate_to_topic => params[:relate_to_topic], :related_class => params[:related_class], :function => 'remove'
  end

  def unlink_related
    @related_to_topic = Topic.find(params[:relate_to_topic])

    unless params[:item].blank?
      for id in params[:item].reject { |k, v| v != "true" }.collect { |k, v| k }
        item = only_valid_zoom_class(params[:related_class]).find(id)

        remove_relation_and_update_zoom_and_related_caches_for(item, @related_to_topic)

        update_zoom_and_related_caches_for(item)
        flash[:notice] = "Successfully removed item relationships."

      end
    end

    redirect_to :controller => 'search', :action => 'find_related', :relate_to_topic => params[:relate_to_topic], :related_class => params[:related_class], :function => 'remove'
  end

  # overriding here, to grab title of page, too
  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    # this should prevent the same page from being added to return_to
    # but does not prevent case of differnt size images...
    session[:return_to] = request.request_uri
    session[:return_to_title] = @title
  end

  def redirect_to_search_for(zoom_class)
    redirect_to(:controller => 'search',
                :trailing_slash => true,
                :action => :all,
                :controller_name_for_zoom_class => zoom_class_controller(zoom_class))
  end

  def redirect_to_default_all
    redirect_to(basket_all_url(:controller_name_for_zoom_class => zoom_class_controller(DEFAULT_SEARCH_CLASS)))
  end

  def redirect_to_all_for(controller)
    redirect_to(basket_all_url(:controller_name_for_zoom_class => controller))
  end

  def redirect_to_show_for(item, options = {})

    # By default, assume redirect to public version.
    options = {
      :private => false
    }.merge(options)

    path_hash = {
      :urlified_name  => item.basket.urlified_name,
      :controller     => zoom_class_controller(item.class.name),
      :action         => 'show',
      :id             => item
    }

    # Redirect to private version if item is private.
    if options[:private]
      path_hash.merge!({ :private => "true" })
    end

    redirect_to url_for(path_hash)
  end

  def url_for_dc_identifier(item)
    url_for(:controller => zoom_class_controller(item.class.name), :action => 'show', :id => item, :format => nil, :urlified_name => item.basket.urlified_name)
  end

  def render_oai_record_xml(options = {})
    item = options[:item]
    to_string = options[:to_string] || false
    if to_string
      render_to_string(:file => "#{RAILS_ROOT}/app/views/search/oai_record.rxml", :layout => false, :content_type => 'text/xml', :locals => { :item => item })
    else
      render :file => "#{RAILS_ROOT}/app/views/search/oai_record.rxml", :layout => false, :content_type => 'text/xml', :locals => { :item => item }
    end
  end

  def user_to_dc_creator_or_contributor(user)
    user.user_name
  end

  def rescue_404
    @title = "404 Not Found"
    @displaying_404 = true
    render :template => "errors/error404", :layout => "application", :status => "404"
  end

  def rescue_500(template)
    @title = "500 Internal Server Error"
    render :template => "errors/#{template}", :layout => "application", :status => "500"
  end

  def rescue_action_in_public(exception)
    #logger.info(exception)
    case exception
      when ActiveRecord::RecordNotFound, ActiveRecord::RecordInvalid then
      rescue_404
    when BackgrounDRb::NoServerAvailable then
      rescue_500('backgroundrb_connection_failed')
    else
      if exception.to_s.match(/Connect\ failed/)
        rescue_500('zebra_connection_failed')
      else
        raise
      end
    end
  end

  def local_request?
    false
  end

  def update_params_with_raw_tag_list
    # only do this for a zoom_class
    # this will return the model's tableized name
    # if it can't find it, so we have to doublecheck it's a zoom_class
    zoom_class = zoom_class_from_controller(params[:controller])
    if ZOOM_CLASSES.include?(zoom_class)
      item_key = zoom_class.underscore.to_sym
      params[item_key][:raw_tag_list] = params[item_key][:tag_list]
    end
  end

  def clear_caches_and_update_zoom_for_commented_item(item)
    if item.class.name == 'Comment'
      commented_item = item.commentable

      expire_comments_caches_for(commented_item)
      prepare_and_save_to_zoom(commented_item)
    end
  end

  def correct_url_for(item, version = nil)
    correct_action = version.nil? ? 'show' : 'preview'

    options = { :action => correct_action, :id => item }
    options[:version] = version if correct_action == 'preview'

    item_url = nil
    if item.class.name == 'Comment' and correct_action != 'preview'
      commented_item = item.commentable
      item_url = url_for(:controller => zoom_class_controller(commented_item.class.name),
                         :action => correct_action,
                         :id => commented_item,
                         :anchor => item.id,
                         :urlified_name => commented_item.basket.urlified_name)
    else
      item_url = url_for(options)
    end
    item_url
  end

  def stats_by_type_for(basket)
    # prepare a hash of all the stats, so it's nice and easy to pass to partial
    @basket_stats_hash = Hash.new
    # special case: site basket contains everything
    # all contents of site basket plus all other baskets' contents

    # pending items are counted
    conditions = "title != \'#{BLANK_TITLE}\' AND title != \'#{NO_PUBLIC_VERSION_TITLE}\'"

    if basket == @site_basket
      ZOOM_CLASSES.each do |zoom_class|
        @basket_stats_hash[zoom_class] = Module.class_eval(zoom_class).count(:conditions => conditions)
      end
    else
      ZOOM_CLASSES.each do |zoom_class|
        @basket_stats_hash[zoom_class] = basket.send(zoom_class.tableize).count(:conditions => conditions)
      end
    end
  end

  def prepare_short_summary(source_string, length = 30, end_string = '')
    require 'hpricot'
    source_string = source_string.to_s
    # length is how many words, rather than characters
    words = source_string.split()
    short_summary = words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')

    # make sure that tags are closed
    Hpricot(short_summary).to_html
  end

  # this happens after the basket on the item has been changed already
  def update_comments_basket_for(item, original_basket)
    if item.class.name != 'Comment'
      new_basket = item.basket
      if new_basket != original_basket
        item.comments.each do |comment|
          # get rid of zoom record that it tied to old basket
          zoom_destroy_for(comment)
          comment.basket = new_basket
          if comment.save
            # moving the comment adds a version
            comment.add_as_contributor(current_user)
          end
          # generate the new zoom record
          # with the new basket
          prepare_and_save_to_zoom(comment)
        end
      end
    end
  end

  def after_successful_zoom_item_update(item)
    # add this to the user's empire of contributions
    # TODO: allow current_user whom is at least moderator to pick another user
    # as contributor
    # uses virtual attr as hack to pass version to << method
    item.add_as_contributor(current_user, item.max_version)

    # if the basket has been changed, make sure comments are moved, too
    update_comments_basket_for(item, @current_basket)

    # finally, sync up our search indexes
    prepare_and_save_to_zoom(item)
  end

  def history_url(item)
    url_for :controller => zoom_class_controller(item.class.name), :action => :history, :id => item
  end

  def rss_tag(options = { })
    auto_detect = !options[:auto_detect].nil? ? options[:auto_detect] : true
    replace_page_with_rss = !options[:replace_page_with_rss].nil? ? options[:replace_page_with_rss] : false

    tag = String.new

    if auto_detect
      tag = "<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" "
    else
      logger.debug("wtf?")
      tag = "<a "
    end

    tag += "href=\""+ request.protocol + request.host
    # split everything before the query string and the query string
    url = request.request_uri.split('?')

    # now split the path up and add rss to it
    path_elements = url[0].split('/')

    path_elements.pop if replace_page_with_rss

    path_elements << 'rss.xml'
    new_path = path_elements.join('/')
    tag +=  new_path
    # if there is a query string, tack it on the end
    if !url[1].nil?
      logger.debug("what is query string: #{url[1].to_s}")
      tag += "?#{url[1].to_s}"
    end
    if auto_detect
      tag +=  "\" />"
    else
      tag += "\">" # A tag has a closing </a>
    end
  end

  def render_full_width_content_wrapper?
    if params[:controller] == 'baskets' and ['edit', 'update', 'homepage_options', 'appearance'].include?(params[:action])
      return false
    elsif ['moderate', 'members', 'importers'].include?(params[:controller]) and ['list', 'create', 'new', 'potential_new_members'].include?(params[:action])
      return false
    elsif params[:controller] == 'index_page' and params[:action] == 'index'
      return false
    elsif params[:controller] == 'account' and params[:action] == 'show'
      return true
    elsif !['show', 'preview', 'show_private'].include?(params[:action])
      return true
    else
      return false
    end
  end

  def public_or_private_version_of(item)
    if params[:private] == "true" && item.has_private_version? && permitted_to_view_private_items?
      item.private_version!
    else
      item
    end
  end

  # checks to see if a user has access to view this private item.
  # result cached so the function can be used several times on the
  # same request
  def permitted_to_view_private_items?
    @permitted_to_view_private_items ||= logged_in? &&
                                         permit?("site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket")
  end

  # checks if the user is requesting a private version of an item, and see
  # if they are allowed to do so
  def accessing_private_version_and_allowed?
    (!params[:private].nil? and params[:private] == "true" and permitted_to_view_private_items?)
  end

  # checks if the user is requesting a private search of a basket, and see
  # if they are allowed to do so
  def accessing_private_search_and_allowed?
    (!params[:privacy_type].nil? and params[:privacy_type] == "private" and permitted_to_view_private_items?)
  end

  # used to get the acceptable privacy type (that is the current requested
  # privacy type unless not allowed), and return a value
  # (used in caching to decide whether to look for public or private fragments)
  def get_acceptable_privacy_type(value_when_public, value_when_private)
    if accessing_private_version_and_allowed?
      value_when_private
    else
      value_when_public
    end
  end

  # Check whether the attached files for a given item should be displayed
  # Note this is independent of file privacy.
  def show_attached_files_for?(item)
    if item.respond_to?(:private) and item.private?

      # If viewing the private version of an item, then the user already has permission to
      # see any attached files.
      true
    else

      # Otherwise, show the files if viewing a public, non-disputed and non-placeholder
      # version
      !item.disputed_or_not_available?
    end
  end

  def private_redirect_attribute_for(item)
    item.respond_to?(:private) && item.private? ? "true" : "false"
  end

  def slideshow
    # Instantiate a new slideshow object on the slideshow session key
    session[:slideshow] ||= HashWithIndifferentAccess.new
    Slideshow.new(session[:slideshow])
  end

  # Append a query string to a URL.
  def append_options_to_url(url, options)
    options = options.join("&") if options.is_a?(Array)

    append_operator = url.include?("?") ? "&" : "?"
    url + append_operator + options
  end

  # setup a few variables that will be used on topic/audio/etc items
  # pass in the item type in class format (AudioRecording), and whether
  # you want the item always loaded, or only when everything isn't cached
  def prepare_item_variables_for(zoom_class, always_load=false)
    if !ZOOM_CLASSES.member?(zoom_class)
      raise(ArgumentError, "zoom_class name expected. #{zoom_class} is not registered in #{ZOOM_CLASSES}.")
    end

    # on certain items, always load the item, since we check
    # for blank version to determine whether to show it
    @item = @current_basket.send(zoom_class.tableize).find(params[:id]) if always_load

    if permitted_to_view_private_items?
      @show_privacy_chooser = true
    end

    if params[:format] == 'xml' or !has_all_fragments? or accessing_private_version_and_allowed?
      @item = @current_basket.send(zoom_class.tableize).find(params[:id]) unless always_load
      @item = @item.private_version! if params[:private] == "true" and @item.has_private_version? and permitted_to_view_private_items?

      if params[:format] == 'xml' or !has_fragment?({:part => ("page_title_" + get_acceptable_privacy_type("public", "private")) })
        @title = @item.title
      end

      if params[:format] == 'xml' or !has_fragment?({:part => ("contributor_" + get_acceptable_privacy_type("public", "private")) })
        @creator = @item.creator
        @last_contributor = @item.contributors.last || @creator
      end

      if logged_in? and @at_least_a_moderator
        if params[:format] == 'xml' or !has_fragment?({:part => ("comments-moderators_" + get_acceptable_privacy_type("public", "private"))})
          @comments = @item.non_pending_comments
        end
      else
        if params[:format] == 'xml' or !has_fragment?({:part => ("comments_" + get_acceptable_privacy_type("public", "private"))})
          @comments = @item.non_pending_comments
        end
      end
    end
  end

  # methods that should be available in views as well
  helper_method :prepare_short_summary, :history_url, :render_full_width_content_wrapper?, :permitted_to_view_private_items?, :accessing_private_version_and_allowed?, :accessing_private_search_and_allowed?, :get_acceptable_privacy_type, :current_user_can_see_flagging?,  :current_user_can_see_add_links?, :current_user_can_see_action_menu?, :current_user_can_see_discussion?, :current_user_can_see_private_files_for?, :current_user_can_see_private_files_in_basket?, :show_attached_files_for?, :slideshow, :append_options_to_url

  private

  def current_user_is?(at_least_setting)
    begin
      # everyone can see, just return true
      return true if at_least_setting == 'all users' || at_least_setting.blank?

      # all other settings, you must be at least logged in
      return false unless logged_in?

      # finally, if they are logged in
      # we evaluate matching instance variable if they have the role that matches
      # our basket setting
      instance_variable_get("@#{at_least_setting.gsub(" ", "_")}")
    rescue
      raise "Unknown authentication type: #{$!}"
    end
  end

end
