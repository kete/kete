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
                                            :restore ]

  # basket.urlified_name may change for the default basket
  # so can't rely on it being 'site'
  # this is a good candidate for memcaching
  before_filter :site_basket

  # all topics and content items belong in a basket
  # and will always be specified in our routes
  before_filter :load_basket

  # sets up instance variables for authentication
  include KeteAuthorization

  # if anything is updated or deleted
  # we need toss our show action fragments
  before_filter :expire_show_caches, :only => [ :edit, :destroy ]

  # keep track of tag_list input by version
  before_filter :update_params_with_raw_tag_list, :only => [ :create, :update ]

  # see method definition for details

  before_filter :delete_zoom_record, :only => [ :update ]

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

  def site_basket
    # TODO: cache
    @site_basket ||= Basket.find(1)
  end

  # set the current basket to the default
  # unless we have urlified_name that is different
  # than the default
  # TODO: cache in memcache
  def load_basket
    @current_basket = @site_basket

    if !params[:urlified_name].blank? and params[:urlified_name] != @site_basket.urlified_name
      @current_basket = Basket.find_by_urlified_name(params[:urlified_name])
    end
  end

  # some updates will change the item so that the updating of zoom record
  # will no longer match the existing record
  # and create a new one instead
  # so we delete the existing zoom record here
  # and create a new zoom record in the update
  def delete_zoom_record
    zoom_class = zoom_class_from_controller(params[:controller])
    if ZOOM_CLASSES.include?(zoom_class)
      item = Module.class_eval(zoom_class).find(params[:id])
      zoom_destroy_for(item)
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
    INDEX_PARTS.each do |part|
      expire_fragment(:controller => 'index_page',
                      :action => 'index',
                      :urlified_name => @current_basket.urlified_name,
                      :part => part)
    end
  end

  def expire_fragment_for_all_versions(item, name = {})
    item.versions.find(:all, :select => 'distinct title').each do |version|
      expire_fragment(name.merge(:id => item.id.to_s + format_friendly_for(version.title)))
    end
  end

  # expire the cache fragments for the show action
  # excluding the related cache, this we handle separately
  def expire_show_caches
    if params[:controller] != 'account'
      item = Module.class_eval(zoom_class_from_controller(params[:controller])).find(params[:id])
      expire_show_caches_for(item)
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
            expire_related_caches_for(topic, 'topics')
          end
        end
      else
        # topics need all it's related things expired
        ZOOM_CLASSES.each do |zoom_class|
          expire_fragment_for_all_versions(item, { :action => 'show', :id => item, :related => zoom_class_controller(zoom_class) })
          if zoom_class == 'Topic'
            item.related_topics.each do |related_item|
              expire_related_caches_for(related_item, 'topics')
            end
          else
            item.send(zoom_class.tableize).each do |related_item|
              expire_related_caches_for(related_item, controller)
            end
          end
        end
      end
    end
  end

  def expire_related_caches_for(item, controller = nil)
    related = String.new
    if !controller.nil?
      related = zoom_class_controller(controller)
    else
      if item.class.name != 'topics'
        related = 'topics'
      else
        # topics need all it's related things expired
        ZOOM_CLASSES.each do |zoom_class|
          expire_fragment_for_all_versions(item,
                                           { :urlified_name => item.basket.urlified_name,
                                             :controller => zoom_class_controller(item.class.name),
                                             :action => 'show',
                                             :id => item,
                                             :related => zoom_class_controller(zoom_class) })
        end
        related = nil
      end
    end
    if !related.nil?
      expire_fragment_for_all_versions(item,
                                       { :urlified_name => item.basket.urlified_name,
                                         :controller => zoom_class_controller(item.class.name),
                                         :action => 'show',
                                         :id => item,
                                         :related => related} )
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
    redirect_to_show_for(Topic.find(topic_id), 'topics')
  end

  def update_zoom_and_related_caches_for(item, controller = nil)
    prepare_and_save_to_zoom(item)

    if controller.nil?
      expire_related_caches_for(item, controller)
    else
      expire_related_caches_for(item, controller)
    end
  end

  def add_relation_and_update_zoom_and_related_caches_for(item,new_related_topic)
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
    elsif params[:relate_to_topic_id] and @successful
      @new_related_topic = Topic.find(params[:relate_to_topic_id])

      add_relation_and_update_zoom_and_related_caches_for(item,@new_related_topic)

      where_to_redirect = 'show_related'
    end

    if @successful
      update_zoom_and_related_caches_for(item)

      case where_to_redirect
      when 'show_related'
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = "Related #{item.class.name.humanize} was successfully created."
        redirect_to_related_topic(@new_related_topic)
      when 'commentable'
        redirect_to_show_for(commented_item, zoom_class_controller(commented_item.class.name))
      else
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = "#{item.class.name.humanize} was successfully created."

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
      @existing_relation = @related_to_topic.child_related_topics.count(["topics.id = ?", item])
    else
      related_items = @related_to_topic.send(params[:related_class].tableize.to_sym)
      @existing_relation = related_items.count(["content_item_relations.related_item_id = ?", item])
    end

    if @existing_relation.to_i == 0
      @successful = add_relation_and_update_zoom_and_related_caches_for(item,@related_to_topic)

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

  def redirect_to_show_for(item, controller = nil)
    controller ||= params[:controller]
    redirect_to(url_for(:urlified_name => item.basket.urlified_name,
                        :controller => controller,
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
    render(:file => "#{RAILS_ROOT}/public/404.inc", :layout => true)
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

  def find_version_from_item_and_version(item, version)
    class_name = item.class.name
    return Module.class_eval("#{class_name}::Version").find(:first,
                                                            :conditions => ["#{class_name.underscore}_id = ? and version = ?", item.id, version])
  end

  def flag_version
    # get the item in question based on controller and id passed
    zoom_class = zoom_class_from_controller(params[:controller])
    item = Module.class_eval(zoom_class).find(params[:id])
    flag = params[:flag]

    # we tag the current version with the flag passed
    current_version = find_version_from_item_and_version(item, item.version)
    current_version.tag_list = flag
    current_version.save_tags

    # we revert to most recent version without a flag
    # if one is available, except for duplicates
    reverted = false
    if current_version.version > 1 and flag != 'duplicate'
      last_version_version = current_version.version - 1

      last_version = find_version_from_item_and_version(item, last_version_version)

      last_version_tags_count = last_version.tags.size
      if last_version_version > 1
        while last_version_tags_count > 0
          last_version_version = last_version_version - 1
          last_version = find_version_from_item_and_version(item, last_version_version)
          last_version_tags_count = last_version.tags.size
        end
      end

      if last_version_tags_count == 0
        item.revert_to!(last_version_version)
        item.tag_list = item.raw_tag_list
        item.save_tags
        reverted = true
      end
    end

    # clear caches for the item and rss
    expire_show_caches
    expire_rss_caches

    # update zoom for item
    # TODO: should we update related in case title has changed
    if reverted
      prepare_and_save_to_zoom(item)
    end

    # notify moderators for the basket
    if item.class.name == 'Comment'
      commented_item = item.commentable

      expire_comments_caches_for(commented_item)
      prepare_and_save_to_zoom(commented_item)

      item_url = url_for(:controller => zoom_class_controller(commented_item.class.name),
                         :action => 'show',
                         :id => commented_item,
                         :anchor => @item.id,
                         :urlified_name => commented_item.basket.urlified_name)
    else
      item_url = url_for(:action => 'show', :id => params[:id])
    end
    moderators = find_moderators_for_basket_or_next_in_line(@current_basket)
    moderators.each do |moderator|
      UserNotifier.deliver_item_flagged(moderator, flag, item_url, @current_user)
    end

    flash[:notice] = "Thank you for your input.  A moderator has been notified and will review the item in question."
    flash[:notice] += " The item has been reverted to an earlier version for the time being." if reverted

    redirect_to item_url
  end

  # permission check in controller
  def restore
    zoom_class = zoom_class_from_controller(params[:controller])
    @item = Module.class_eval(zoom_class).find(params[:id])

    # unlike flag_version, we create a new version
    # so we track the restore in our version history
    @item.revert_to(params[:version])
    @item.tag_list = @item.raw_tag_list
    @item.version_comment = "Restored content from revision \# #{params[:version]}."
    @item.save

    # keep track of the moderator's contribution
    @current_user = current_user
    @current_user.version = @item.version
    @item.contributors << @current_user

    # clear caches for the item and rss
    expire_show_caches
    expire_rss_caches

    # update zoom for item
    # TODO: should we update related in case title has changed
    prepare_and_save_to_zoom(@item)

    flash[:notice] = "The content of this #{@item.class.name.humanize} has been restored from the selected revision."

    if @item.class.name == 'Comment'
      commented_item = @item.commentable
      prepare_and_save_to_zoom(commented_item)
      redirect_to url_for(:controller => zoom_class_controller(commented_item.class.name),
                          :action => 'show',
                          :id => commented_item,
                          :anchor => @item.id,
                          :urlified_name => commented_item.basket.urlified_name)
    else
      redirect_to url_for(:action => 'show', :id => params[:id])
    end
  end

  # view history of edits to an item
  # including each version's flags
  # this expects a rhtml template within each controller's view directory
  # so that different types of items can have their history display customized
  def history
    # get the item in question based on controller and id passed
    zoom_class = zoom_class_from_controller(params[:controller])
    @item = Module.class_eval(zoom_class).find(params[:id])

    @versions = @item.versions
  end

  # preview a version of an item
  # assumes a preview templates under the controller
  def preview
    # get the item in question based on controller and id passed
    zoom_class = zoom_class_from_controller(params[:controller])
    @item = Module.class_eval(zoom_class).find(params[:id])
    # no need to preview live version
    if @item.version.to_s == params[:version]
      redirect_to url_for(:action => 'show', :id => params[:id])
    else
      @preview_version = @item.versions.find_by_version(params[:version])
      @flags = Array.new
      @preview_version.tags.each do |tag|
        @flags << tag.name
      end
      @item.revert_to(@preview_version)
    end
  end

  # if we don't have any moderators specified
  # find admins for basket
  # if no admins for basket, go with basket 1 (site) admins
  # if no admins for site, go with any site_admins
  def find_moderators_for_basket_or_next_in_line(basket)
    moderator_role = Role.find(:first,
                               :conditions => ["name = \'moderator\' and authorizable_type = \'Basket\' and authorizable_id = ?", basket.id])
    moderators = Array.new
    if !moderator_role.nil?
      moderators = moderator_role.users
    end

    if moderators.size == 0
      moderator_role = Role.find(:first,
                                 :conditions => ["name = \'admin\' and authorizable_type = \'Basket\' and authorizable_id = ?", basket.id])

      if !moderator_role.nil?
        moderators = moderator_role.users
      end

      if moderators.size == 0
        moderator_role = Role.find(:first,
                                   :conditions => "name = \'admin\' and authorizable_type = \'Basket\' and authorizable_id = 1")
        if !moderator_role.nil?
          moderators = moderator_role.users
        end

        if moderators.size == 0
          moderator_role = Role.find(:first,
                                     :conditions => "name = \'site_admin\'")
          if !moderator_role.nil?
            moderators = moderator_role.users
          end
        end
      end
    end
    return moderators
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

  def prepare_short_summary(source_string,length = 30,end_string = '')
    source_string = source_string.to_s
    # length is how many words, rather than characters
    words = source_string.split()
    short_summary = words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
  end

  def add_contributor_to(item,user)
    user.version = item.version
    item.contributors << user
  end

  # this happens after the basket on the item has been changed already
  def update_comments_basket_for(item,original_basket)
    if item.class.name != 'Comment'
      new_basket = item.basket
      if new_basket != original_basket
        item.comments.each do |comment|
          # get rid of zoom record that it tied to old basket
          zoom_destroy_for(comment)
          comment.basket = new_basket
          if comment.save
            # moving the comment adds a version
            add_contributor_to(comment,current_user)
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
    add_contributor_to(item,current_user)

    # if the basket has been changed, make sure comments are moved, too
    update_comments_basket_for(item,@current_basket)

    # finally, sync up our search indexes
    prepare_and_save_to_zoom(item)
  end

  # methods that should be available in views as well
  helper_method :prepare_short_summary, :zoom_class_controller, :zoom_class_from_controller
end
