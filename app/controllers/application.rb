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

  # setup return_to for the session
  after_filter :store_location, :only => [ :for, :all, :search, :index, :new, :show, :edit]

  # if anything is added, edited, or deleted
  # we need to rebuild our rss caches
  after_filter :expire_rss_caches, :only => [ :create, :edit, :destroy]

  def load_basket
    @current_basket = Basket.new
    if !params[:urlified_name].blank?
      @current_basket = Basket.find_by_urlified_name(params[:urlified_name])
    else
      # the first basket is always the default
      @current_basket = Basket.find(1)
    end
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

  def setup_related_topic_and_zoom_and_redirect(item)
    where_to_redirect = 'show_self'
    if params[:relate_to_topic_id] and @successful
      @new_related_topic = Topic.find(params[:relate_to_topic_id])

      ContentItemRelation.new_relation_to_topic(@new_related_topic.id, item)

      # update the related topic
      # so this new relationship is reflected in search
      prepare_and_save_to_zoom(@new_related_topic)

      where_to_redirect = 'show_related'
    end

    if @successful
      prepare_and_save_to_zoom(item)

      if where_to_redirect == 'show_related'
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = "Related #{item.class.name.humanize} was successfully created."
        redirect_to_related_topic(@new_related_topic)
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

        # in this context, the item being related needs updating, too
        prepare_and_save_to_zoom(item)

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
