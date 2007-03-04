# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  include AuthenticatedSystem

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

  def load_basket
    @current_basket = Basket.new
    if !params[:urlified_name].blank?
      @current_basket = Basket.find_by_urlified_name(params[:urlified_name])
    else
      # the first basket is always the default
      @current_basket = Basket.find(1)
    end
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
    redirect_to(:controller => 'search',
                :trailing_slash => true,
                :action => :all,
                :controller_name_for_zoom_class => zoom_class_controller(zoom_class))
  end

  def redirect_to_default_all
    redirect_to(basket_all_url(:controller_name_for_zoom_class => zoom_class_controller(DEFAULT_SEARCH_CLASS)))
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
  end

  def zoom_class_from_controller(controller)
    zoom_class = String.new
    case controller
      when "images"
      zoom_class = 'StillImage'
      when "video"
      zoom_class = 'Video'
      when "audio"
      zoom_class = 'AudioRecording'
      else
      zoom_class = controller.classify
    end
  end

  def url_for_dc_identifier(item)
    url_for(:controller => zoom_class_controller(item.class.name), :action => 'show', :id => item, :format => nil, :urlified_name => item.basket.urlified_name)
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

  #---- related to extended_fields for content_types

  # populate extended_fields param with xml
  # based on params from the form
  def extended_fields_update_hash_for_item(options = {})
    fields = options[:fields]
    item_key = options[:item_key].to_sym
    logger.debug("inside update param for item")
    params[item_key][:extended_content] = render_to_string(:partial => 'search/field_to_xml',
                                                           :collection => @fields,
                                                           :layout => false,
                                                           :locals => { :item_key => item_key})
    logger.debug("after field_to_xml")
    return params
  end

  alias extended_fields_update_param_for_item extended_fields_update_hash_for_item

  # strip out raw extended_fields and create a valid params hash for new/create/update
  def extended_fields_replacement_params_hash(options = {})
    item_key = options[:item_key].to_sym
    item_class = options[:item_class]

    extra_fields = options[:extra_fields] || Array.new
    extra_fields << 'tag_list'
    extra_fields << 'uploaded_data'

    logger.debug("what are extra fields : #{extra_fields.to_s}")
    replacement_hash = Hash.new

    params[item_key].keys.each do |field_key|
      # we only want real topic columns, not pseudo ones that are handled by extended_content xml
      if Module.class_eval(item_class).column_names.include?(field_key) || extra_fields.include?(field_key)
        replacement_hash = replacement_hash.merge(field_key => params[item_key][field_key])
      end
    end
    logger.debug("end of replacement")
    return replacement_hash
  end

  def extended_fields_and_params_hash_prepare(options = {})
    item_key = options[:item_key]
    item_class = options[:item_class]
    content_type = options[:content_type]
    extra_fields = options[:extra_fields] || Array.new

    logger.debug("inside prepare")
    # grab the content_type fields
    @fields = content_type.content_type_to_field_mappings

    if @fields.size > 0
      extended_fields_update_param_for_item(:fields => @fields, :item_key => item_key)
    end

    return extended_fields_replacement_params_hash(:item_key => item_key, :item_class => item_class, :extra_fields => extra_fields )
  end

  # http://wiki.rubyonrails.com/rails/pages/HowtoConfigureTheErrorPageForYourRailsApp
  def rescue_action_in_public(exception)
    render(:file => "#{RAILS_ROOT}/public/404.inc", :layout => true)
  end
  def local_request?
    false
  end
  
  def help_file
    render(:layout => "layouts/simple", :file => "#{RAILS_ROOT}/public/about/manual-source.html")
  end
end
