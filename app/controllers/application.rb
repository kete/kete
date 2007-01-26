# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem

  # only permit site members to add/delete things
  before_filter :login_required, :except => [ :login, :signup, :logout, :show, :search, :index, :list]

  # all topics and content items belong in a basket
  # some controllers won't need it, but it shouldn't hurt have it available
  # and will always be specified in our routes
  before_filter :load_basket

  # setup return_to for the session
  after_filter :store_location, :only => [ :search, :index, :new, :show, :edit]

  def load_basket
    @current_basket = Basket.new
    if !params[:urlified_name].blank?
      @current_basket = Basket.find_by_urlified_name(params[:urlified_name])
    else
      # the first basket is always the default
      @current_basket = Basket.find(1)
    end
    return @current_basket
  end

  def redirect_to_related_topic(topic_id)
    # TODO: doublecheck this isn't too expensive, maybe better to find_by_sql
    topic = Topic.find_by_id(topic_id)
    basket = topic.basket
    redirect_to :action => 'show', :controller => 'topics', :id => topic_id, :urlified_name => basket.urlified_name
  end

  def setup_related_topic_and_zoom_and_redirect(item)
    where_to_redirect = 'show_self'
    if params[:relate_to_topic_id] and @successful
      @new_related_topic = find(params[:relate_to_topic_id])
      ContentItemRelation.new_relation_to_topic(@new_related_topic, item)

      # update the related topic
      # so this new relationship is reflected in search
      prepare_and_save_to_zoom(@new_related_topic)

      where_to_redirect = 'show_related'
    end

    if @successful
      prepare_and_save_to_zoom(item)

      if where_to_redirect == 'show_related'
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = 'Related #{item.class.name.humanize} was successfully created.'
        redirect_to_related_topic(@new_related_topic.id)
      else
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = "#{item.class.name.humanize} was successfully created."
        params[:topic] = replacement_topic_hash
        redirect_to :action => 'show', :id => item
      end
    else
        render :action => 'new'
    end
  end

  def zoom_destroy_and_redirect(zoom_class,pretty_zoom_class = nil)
    if pretty_zoom_class.nil?
      pretty_zoom_class = zoom_class
    end
    begin
      item = Module.class_eval(zoom_class).find(params[:id])

      prepare_zoom(item)
      @successful = item.destroy
    rescue
      flash[:error], @successful  = $!.to_s, false
    end

    if @successful
      flash[:notice] = "#{pretty_zoom_class} was successfully deleted."
    end
    redirect_to :action => 'list'
  end

  # overriding here, to grab title of page, too
  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.request_uri
    session[:return_to_title] = @title
  end

  def redirect_to_search_for(zoom_class)
    redirect_to(:controller => 'search', :current_class => zoom_class)
  end

  # is this redundant with application_helper def?
  def zoom_class_controller(zoom_class)
    zoom_class_controller = String.new
    case zoom_class
      when "StillImage"
      zoom_class_controller = 'images'
      when "Video"
      zoom_class_controller = 'video'
      when "AudioRecording"
      zoom_class_controller = 'audio'
      else
      zoom_class_controller = zoom_class.tableize
    end
    return zoom_class_controller
  end

  def url_for_dc_identifier(item)
    return url_for(:controller => zoom_class_controller(item.class.name), :action => 'show', :id => item.id, :format => nil, :urlified_name => item.basket.urlified_name)
  end

  def prepare_zoom(item)
    # only do this for members of ZOOM_CLASSES
    if ZOOM_CLASSES.include?(item.class.name)
      begin
        item.oai_record = render_oai_record_xml(:item => item, :to_string => true)
        logger.debug("what is oai_record: #{item.oai_record}")
        item.basket_urlified_name = @current_basket.urlified_name
      rescue
        logger.error("prepare_and_save_to_zoom error: #{$!.to_s}")
      end
    end
  end

  def prepare_and_save_to_zoom(item)
    prepare_zoom(item)
    item.zoom_save
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
    user.login
  end

end
