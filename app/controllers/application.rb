# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  include ZoomControllerHelpers

  include ExtendedFieldsControllerHelpers

  include FriendlyUrls

  # for the remember me functionality
  before_filter :login_from_cookie

  # only permit site members to add/delete things
  before_filter :login_required, :only => [ :new, :pick_topic_type, :create,
                                            :edit, :update, :destroy,
                                            :link_related,
                                            :link_index_topic,
                                            :flag_version,
                                            :restore,
                                            :reject]

  # all topics and content items belong in a basket
  # and will always be specified in our routes
  before_filter :load_standard_baskets

  # sets up instance variables for authentication
  include KeteAuthorization

  # if anything is updated or deleted
  # we need toss our show action fragments
  before_filter :expire_show_caches, :only => [ :edit, :destroy ]

  # keep track of tag_list input by version
  before_filter :update_params_with_raw_tag_list, :only => [ :create, :update ]

  # see method definition for details

  before_filter :delete_zoom_record, :only => [ :update, :flag_version, :restore ]

  # we often need baskets for edits
  before_filter :load_array_of_baskets, :only => [ :edit, :update ]

  # setup return_to for the session
  after_filter :store_location, :only => [ :for, :all, :search, :index, :new, :show, :edit]

  # if anything is added, edited, or deleted
  # we need to rebuild our rss caches
  after_filter :expire_rss_caches, :only => [ :create, :update, :destroy]

  # if anything is added, edited, or deleted in a basket
  # we need toss our basket index page fragments
  after_filter :expire_basket_index_caches, :only => [ :create,
                                                       :update,
                                                       :destroy,
                                                       :add_index_topic, :link_index_topic]
  # set the current basket to the default
  # unless we have urlified_name that is different
  # than the default
  # TODO: cache in memcache
  def load_standard_baskets
    # could DRY this up with one query for all the baskets
    @site_basket ||= Basket.find(1)
    @help_basket ||= Basket.find(HELP_BASKET)
    @about_basket ||= Basket.find(ABOUT_BASKET)
    @documentation_basket ||= Basket.find(DOCUMENTATION_BASKET)

    @standard_baskets ||= [1, HELP_BASKET, ABOUT_BASKET, DOCUMENTATION_BASKET]

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
  SHOW_PARTS = ['details', 'contributions', 'edit', 'delete', 'zoom_reindex', 'flagging_links', 'comments-moderators', 'comments']

  INDEX_PARTS = [ 'details', 'edit', 'recent_topics', 'search', 'extra_side_bar_html', 'archives', 'tags']

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
    # slight change for postgresql
    # this works with mysql and postgresql, not sure about sqlite or oracle
    item.versions.find(:all, :select => 'distinct title, version').each do |version|
      expire_fragment(name.merge(:id => item.id.to_s + format_friendly_for(version.title)))
    end
  end

  # expire the cache fragments for the show action
  # excluding the related cache, this we handle separately
  def expire_show_caches
    no_caches_controllers = ['account', 'members']
    if !no_caches_controllers.include?(params[:controller])
      expire_show_caches_for(item_from_controller_and_id)
    end
  end

  def expire_show_caches_for(item)
    # only do this for zoom_classes
    item_class = item.class.name
    controller = zoom_class_controller(item_class)
    return unless ZOOM_CLASSES.include?(item_class)

    SHOW_PARTS.each do |part|
      # we have to do this for each distinct title the item previously had
      # because old titles' friendly urls won't be matched in our expiry otherwise
      expire_fragment_for_all_versions(item, { :controller => controller, :action => 'show', :id => item, :part => part })
    end

    # images have an additional cache
    # and topics may also have a basket index page cached
    if controller == 'images'
      expire_fragment_for_all_versions(item, { :controller => controller, :action => 'show', :id => item, :part => 'caption' })
    elsif controller== 'topics'
      if !item.index_for_basket.nil?
        # slight overkill, but most parts
        # would need to be expired anyway
        INDEX_PARTS.each do |part|
          expire_fragment(:urlified_name => item.index_for_basket.urlified_name, :part => part)
        end
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
    end
  end

  def expire_contributions_caches_for(item)
    expire_fragment_for_all_versions(item,
                                     { :urlified_name => item.basket.urlified_name,
                                       :controller => zoom_class_controller(item.class.name),
                                       :action => 'show',
                                       :id => item,
                                       :part => 'contributions' })
  end

  def expire_comments_caches_for(item)
    ['comments-moderators', 'comments'].each do |comment_cache|
      expire_fragment_for_all_versions(item,
                                       { :urlified_name => item.basket.urlified_name,
                                         :controller => zoom_class_controller(item.class.name),
                                         :action => 'show',
                                         :id => item,
                                         :part => comment_cache } )
    end
  end

  # cheating, we know that we are using file store, rather than mem_cache
  # TODO: put an if mem_cache ... use read_fragment({:part => part})
  # wrapped in this method
  def has_fragment?(name = {})
    File.exists?("#{RAILS_ROOT}/tmp/cache/#{fragment_cache_key(name).gsub("?", ".") + '.cache'}")
  end

  # used by show actions to determine whether to load item
  def has_all_fragments?
    if params[:controller] != 'index_page'
      SHOW_PARTS.each do |part|
        return false unless has_fragment?({:part => part})
      end
    end

    case params[:controller]
    when 'index_page'
      INDEX_PARTS.each do |part|
        return false unless has_fragment?({:part => part})
      end
    when 'topics'
      ZOOM_CLASSES.each do |zoom_class|
        if zoom_class != 'Comment'
          return false unless has_fragment?({:related => zoom_class_controller(zoom_class)})
        end
      end
    else
      return false unless has_fragment?({:related => 'topics'})
    end
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

  def setup_related_topic_and_zoom_and_redirect(item, commented_item = nil)
    where_to_redirect = 'show_self'
    if !commented_item.nil? and @successful
      where_to_redirect = 'commentable'
    elsif params[:relate_to_topic] and @successful
      @new_related_topic = Topic.find(params[:relate_to_topic])

      add_relation_and_update_zoom_and_related_caches_for(item, @new_related_topic)

      where_to_redirect = 'show_related'
    end

    if @successful
      update_zoom_and_related_caches_for(item)

      case where_to_redirect
      when 'show_related'
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = "Related #{zoom_class_humanize(item.class.name)} was successfully created."
        redirect_to_related_topic(@new_related_topic)
      when 'commentable'
        redirect_to_show_for(commented_item)
      else
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = "#{zoom_class_humanize(item.class.name)} was successfully created."

        redirect_to_show_for(item)
      end
    else
      render :action => 'new'
    end
  end

  def link_related
    @related_to_topic = Topic.find(params[:related_to_topic])
    item = Module.class_eval(params[:related_class]).find(params[:topic])

    if params[:related_class] =='Topic'
      @existing_relation = @related_to_topic.related_topics.include?(item)
    else
      @existing_relation = @related_to_topic.send(params[:related_class].tableize).include?(item)
    end

    if !@existing_relation
      @successful = add_relation_and_update_zoom_and_related_caches_for(item, @related_to_topic)

      if @successful
        # in this context, the item being related needs updating, too
        update_zoom_and_related_caches_for(item)

        render(:layout => false, :exists => false, :success => true)
      end
    else
      render(:layout => false, :exists => '1')
    end
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

  def redirect_to_show_for(item)
    redirect_to(url_for(:urlified_name => item.basket.urlified_name,
                        :controller => zoom_class_controller(item.class.name),
                        :action => 'show',
                        :id => item))
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

  # http://wiki.rubyonrails.com/rails/pages/HowtoConfigureTheErrorPageForYourRailsApp
  def rescue_action_in_public(exception)
    render(:file => "#{RAILS_ROOT}/public/404.html", :layout => true)
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

  # flagging related

  # added so users can add a helpful message with details for moderator
  # reviewing the flagging
  def flag_form
    # use one form template for all controllers
    render :template => '/search/flag_form'
  end

  def flag_version
    item = item_from_controller_and_id
    flag = params[:flag]

    # we tag the current version with the flag passed
    # and revert to an unflagged version
    # or create a blank unflagged version if necessary
    flagged_version = item.flag_live_version_with(flag)

    # if the user entered a message to do with the flag
    # update the tagging with it
    if !params[:message][0].blank?
      tagging = flagged_version.taggings.find_by_tag_id(Tag.find_by_name(flag))
      tagging.message = params[:message][0]
      tagging.save
    end

    flagging_clear_caches_and_update_zoom(item)

    clear_caches_and_update_zoom_for_commented_item(item)

    item_url = correct_url_for(item)

    @current_basket.moderators_or_next_in_line.each do |moderator|
      UserNotifier.deliver_item_flagged(moderator, flag, item_url, @current_user, params[:message])
    end

    flash[:notice] = "Thank you for your input.  A moderator has been notified and will review the item in question. The item has been reverted to a non-contested version for the time being."
    redirect_to item_url
  end

  def flagging_clear_caches_and_update_zoom(item)
    # clear caches for the item and rss
    expire_show_caches
    expire_rss_caches

    # a before filter has already dropped the item
    # from the search
    # only reinstate it
    # if not blank
    if !item.already_at_blank_version?
      # update zoom for item
      prepare_and_save_to_zoom(item)
    end
  end

  def clear_caches_and_update_zoom_for_commented_item(item)
    if item.class.name == 'Comment'
      commented_item = item.commentable

      expire_comments_caches_for(commented_item)
      prepare_and_save_to_zoom(commented_item)
    end
  end

  def correct_url_for(item)
    item_url = nil
    if item.class.name == 'Comment'
      item_url = url_for(:controller => zoom_class_controller(commented_item.class.name),
                         :action => 'show',
                         :id => commented_item,
                         :anchor => item.id,
                         :urlified_name => commented_item.basket.urlified_name)
    else
      item_url = url_for(:action => 'show', :id => item)
    end
    item_url
  end

  # permission check in controller
  # reverts to version
  # and removes flags on that version
  def restore
    @item = item_from_controller_and_id

    # if version we are about to supersede
    # is blank, flag it as blank for clarity in the history
    # this doesn't do the reversion in itself
    @item.flag_at_with(@item.version, BLANK_FLAG) if @item.already_at_blank_version?

    # unlike flag_version, we create a new version
    # so we track the restore in our version history
    @item.revert_to(params[:version])
    @item.tag_list = @item.raw_tag_list
    @item.version_comment = "Content from revision \# #{params[:version]}."
    @item.do_not_moderate = true
    @item.save

    # keep track of the moderator's contribution
    @item.add_as_contributor(current_user)

    # now that this item is approved by moderator
    # we get rid of pending flag
    # then flag it as reviewed
    @item.change_pending_to_reviewed_flag(params[:version])

    flagging_clear_caches_and_update_zoom(@item)

    clear_caches_and_update_zoom_for_commented_item(@item)

    flash[:notice] = "The content of this #{zoom_class_humanize(@item.class.name)} has been approved from the selected revision."

    redirect_to correct_url_for(@item)
  end

  def reject
    @item = item_from_controller_and_id

    @item.reject_this(params[:version])

    flash[:notice] = "This version of this #{zoom_class_humanize(@item.class.name)} has been rejected."

    redirect_to correct_url_for(@item)
  end

  # view history of edits to an item
  # including each version's flags
  # this expects a rhtml template within each controller's view directory
  # so that different types of items can have their history display customized
  def history
    @item = item_from_controller_and_id
    @versions = @item.versions
    # one template (with logic) for all controllers
    render :template => 'topics/history'
  end

  # preview a version of an item
  # assumes a preview templates under the controller
  def preview
    @item = item_from_controller_and_id

    # no need to preview live version
    if @item.version.to_s == params[:version]
      redirect_to url_for(:action => 'show', :id => params[:id])
    else
      @preview_version = @item.versions.find_by_version(params[:version])
      @flags = Array.new
      @flag_messages = Array.new
      @preview_version.taggings.each do |tagging|
        @flags << tagging.tag.name
        @flag_messages << tagging.message
      end
      @item.revert_to(@preview_version)
    end
    # one template (with logic) for all controllers
    render :template => 'topics/preview'
  end

  def prepare_topic_for_show
    if !@is_fully_cached or params[:format] == 'xml'
      if params[:id].nil?
        # this is for a basket homepage
        @topic = @current_basket.index_topic
      else
        # plain old topic show
        @topic = @current_basket.topics.find(params[:id])
      end
      if !@topic.nil?
        @title = @topic.title
      end
    end

    if !@is_fully_cached and @topic.nil?
      return
    else
      if !@is_fully_cached
        if !has_fragment?({:part => 'contributions' }) or params[:format] == 'xml'
          @creator = @topic.creators.first
          @last_contributor = @topic.contributors.last || @creator
        end

        if !has_fragment?({:part => 'comments' }) or !has_fragment?({:part => 'comments-moderators' }) or params[:format] == 'xml'
          @comments = @topic.comments
        end
      end
    end
  end

  def stats_by_type_for(basket)
    # prepare a hash of all the stats, so it's nice and easy to pass to partial
    @basket_stats_hash = Hash.new
    # special case: site basket contains everything
    # all contents of site basket plus all other baskets' contents
    if basket == @site_basket
      ZOOM_CLASSES.each do |zoom_class|
        @basket_stats_hash[zoom_class] = Module.class_eval(zoom_class).count
      end
    else
      ZOOM_CLASSES.each do |zoom_class|
        items = basket.send(zoom_class.tableize)
        @basket_stats_hash[zoom_class] = items.size
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
    item.add_as_contributor(current_user)

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
    if params[:controller] == 'index_page' and params[:action] == 'index'
      return false
    elsif params[:action] != 'show'
      return true
    else
      return false
    end
  end

  # methods that should be available in views as well
  helper_method :prepare_short_summary, :zoom_class_controller, :zoom_class_from_controller, :zoom_class_humanize, :zoom_class_plural_humanize, :history_url, :render_full_width_content_wrapper?

end
