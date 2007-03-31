# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  include ZoomControllerHelpers

  include ExtendedFieldsControllerHelpers

  # for the remember me functionality
  before_filter :login_from_cookie

  # only permit site members to add/delete things
  before_filter :login_required, :only => [ :new, :pick_topic_type, :create, :edit, :update, :destroy, :link_related]

  # all topics and content items belong in a basket
  # some controllers won't need it, but it shouldn't hurt have it available
  # and will always be specified in our routes
  before_filter :load_basket

  # sets up instance variables for authentication
  include KeteAuthorization

  # if anything is updated or deleted
  # we need toss our show action fragments
  before_filter :expire_show_caches, :only => [ :update, :destroy ]

  # setup return_to for the session
  after_filter :store_location, :only => [ :for, :all, :search, :index, :new, :show, :edit]

  # if anything is added, edited, or deleted
  # we need to rebuild our rss caches
  after_filter :expire_rss_caches, :only => [ :create, :update, :destroy]

  def load_basket
    @current_basket = Basket.new
    if !params[:urlified_name].blank?
      @current_basket = Basket.find_by_urlified_name(params[:urlified_name])
    else
      # the first basket is always the default
      @current_basket = Basket.find(1)
    end
  end

  # caching related
  SHOW_PARTS = ['details', 'contributions', 'edit', 'delete', 'zoom_reindex', 'comments']

  # expire the cache fragments for the show action
  # excluding the related cache, this we handle separately
  def expire_show_caches
    SHOW_PARTS.each do |part|
      expire_fragment(:action => 'show', :id => params[:id], :part => part)
    end
    # images have an additional cache
    if params[:controller] == 'images'
      expire_fragment(:action => 'show', :id => params[:id], :part => 'caption')
    end

    # if we are deleting the thing
    # also delete it's related caches
    # as well as related caches of things it's related to
    if params[:action] == 'destroy'
      things_class = zoom_class_from_controller(params[:controller])
      thing_to_delete = Module.class_eval(things_class).find(params[:id])

      if params[:controller] != 'topics'
        expire_fragment(:action => 'show', :id => thing_to_delete, :related => 'topics')
        # expire any related topics related caches
        thing_to_delete.topics.each do |topic|
          expire_related_caches_for(topic, 'topics')
        end
      else
        # topics need all it's related things expired
        ZOOM_CLASSES.each do |zoom_class|
          expire_fragment(:action => 'show', :id => thing_to_delete, :related => zoom_class_controller(zoom_class))
          if zoom_class == 'Topic'
            thing_to_delete.related_topics.each do |item|
              expire_related_caches_for(item, 'topics')
            end
          else
            thing_to_delete.send(zoom_class.tableize).each do |item|
              expire_related_caches_for(item, params[:controller])
            end
          end
        end
      end
    end
  end

  def expire_related_caches_for(item, controller = nil)
    if !controller.nil?
      expire_fragment(:urlified_name => item.basket.urlified_name,
                      :controller => zoom_class_controller(item.class.name),
                      :action => 'show',
                      :id => item,
                      :related => zoom_class_controller(controller))
    else
      if item.class.name != 'topics'
        expire_fragment(:urlified_name => item.basket.urlified_name,
                        :controller => zoom_class_controller(item.class.name),
                        :action => 'show',
                        :id => item,
                        :related => 'topics')
      else
        # topics need all it's related things expired
        ZOOM_CLASSES.each do |zoom_class|
          expire_fragment(:urlified_name => item.basket.urlified_name,
                          :controller => zoom_class_controller(item.class.name),
                          :action => 'show',
                          :id => item,
                          :related => zoom_class_controller(zoom_class))
        end
      end
    end
  end

  def expire_contributions_caches_for(item)
    expire_fragment(:urlified_name => item.basket.urlified_name,
                    :controller => zoom_class_controller(item.class.name),
                    :action => 'show',
                    :id => item,
                    :part => 'contributions')
  end

  def expire_comments_caches_for(item)
    expire_fragment(:urlified_name => item.basket.urlified_name,
                    :controller => zoom_class_controller(item.class.name),
                    :action => 'show',
                    :id => item,
                    :part => 'comments')
  end

  # cheating, we know that we are using file store, rather than mem_cache
  def has_fragment?(name = {})
    File.exists?("#{RAILS_ROOT}/tmp/cache/#{fragment_cache_key(name).gsub("?", ".") + '.cache'}")
  end

  # used by show actions to determine whether to load item
  def has_all_fragments?
    SHOW_PARTS.each do |part|
      return false unless has_fragment?({:part => part})
    end
    if params[:controller] == 'topics'
      ZOOM_CLASSES.each do |zoom_class|
        return false unless has_fragment?({:related => zoom_class_controller(zoom_class)})
      end
    else
        return false unless has_fragment?({:related => 'topics'})
    end
    return true
  end

  # remove rss feeds under all and search directories
  # for the class of thing that was just added
  def expire_rss_caches(basket = nil)
    basket ||= @current_basket

    if @current_basket.nil?
      load_basket
      basket ||= @current_basket
    end

    # since site searches all other baskets, too
    # we need to expire it's cache, too
    if @current_basket.urlified_name != 'site'
      expire_page(:controller => 'search', :action => 'rss', :urlified_name => 'site', :controller_name_for_zoom_class => params[:controller])
    end

    expire_page(:controller => 'search', :action => 'rss', :urlified_name => basket.urlified_name, :controller_name_for_zoom_class => params[:controller])

  end

  def redirect_to_related_topic(topic_id)
    # TODO: doublecheck this isn't too expensive, maybe better to find_by_sql
    topic = Topic.find(topic_id)
    basket = topic.basket
    redirect_to :action => 'show', :controller => 'topics', :id => topic, :urlified_name => basket.urlified_name
  end

  def setup_related_topic_and_zoom_and_redirect(item, commented_item = nil)
    where_to_redirect = 'show_self'
    if !commented_item.nil? and @successful
      where_to_redirect = 'commentable'
    elsif params[:relate_to_topic_id] and @successful
      @new_related_topic = Topic.find(params[:relate_to_topic_id])

      ContentItemRelation.new_relation_to_topic(@new_related_topic.id, item)

      # update the related topic
      # so this new relationship is reflected in search
      prepare_and_save_to_zoom(@new_related_topic)

      # make sure the topics cache for this type of item is cleared
      expire_related_caches_for(@new_related_topic, zoom_class_controller(item.class.name))

      where_to_redirect = 'show_related'
    end

    if @successful
      prepare_and_save_to_zoom(item)

      expire_related_caches_for(item)

      case where_to_redirect
      when 'show_related'
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = "Related #{item.class.name.humanize} was successfully created."
        redirect_to_related_topic(@new_related_topic)
      when 'commentable'
        redirect_to url_for(:controller => zoom_class_controller(commented_item.class.name),
                            :action => 'show',
                            :id => commented_item,
                            :urlified_name => commented_item.basket.urlified_name)
      else
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = "#{item.class.name.humanize} was successfully created."
        redirect_to :action => 'show', :id => item
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
      @successful = ContentItemRelation.new_relation_to_topic(@related_to_topic.id, item)

      if @successful
        # update the related topic
        # so this new relationship is reflected in search
        prepare_and_save_to_zoom(@related_to_topic)

        expire_related_caches_for(@related_to_topic, zoom_class_controller(item.class.name))

        # in this context, the item being related needs updating, too
        prepare_and_save_to_zoom(item)

        expire_related_caches_for(item)

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

end
