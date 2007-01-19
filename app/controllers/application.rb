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

  # TODO: replace with in oai_record where appropriate
  def url_for_dc_identifier(item)
    return url_for(:controller => zoom_class_controller(item.class.name), :action => 'show', :id => item.id, :format => nil, :urlified_name => item.basket.urlified_name)
  end

  def prepare_and_save_to_zoom(item)
    # only do this for members of ZOOM_CLASSES
    if ZOOM_CLASSES.include?(item.class.name)
      begin
        item.oai_record = render_to_string(:template => "#{zoom_class_controller(item.class.name)}/oai_record",
                                           :layout => false)
        logger.debug("what is oai_record: #{item.oai_record}")
        item.basket_urlified_name = @current_basket.urlified_name

        # that should do it for preparing our record for zoom
        # shoot it off to our z39.50 server
        item.zoom_save
      rescue
        logger.error("prepare_and_save_to_zoom error: #{$!.to_s}")
      end
    end
  end
end
