# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  include DefaultUrlOptions
  include KeteAuthorisationSettings

  before_filter :set_locale
  # first take the locale in the url, then the session[:locale],
  # then the users locale, finally the default site locale
  def set_locale
    available_locales = I18n.available_locales_with_labels
    if params[:locale] && available_locales.key?(params[:locale])
      I18n.locale = params[:locale]
    elsif session[:locale] && available_locales.key?(session[:locale])
      I18n.locale = session[:locale]
    elsif current_user != :false && available_locales.key?(current_user.locale)
      I18n.locale = current_user.locale
    else
      I18n.locale = I18n.default_locale
    end
    session[:locale] = I18n.locale # need to make sure this persists
  end

  # See lib/ssl_helpers.rb
  include SslHelpers

  include AuthenticatedSystem

  include ZoomControllerHelpers

  include FriendlyUrls

  include Utf8UrlFor

  include ZoomSearch

  include PreviousSearches

  include KeteUrlFor

  # for the remember me functionality
  before_filter :login_from_cookie

  # Setup HTTP Basic Authentication if we have an SITE_LOCKDOWN constant that
  # isn't a blank hash (set in config/initializers/site_lockdown_auth.rb)
  before_filter :password_protect
  def password_protect
    unless SITE_LOCKDOWN.blank?
      authenticate_or_request_with_http_basic do |user_name, password|
        user_name == SITE_LOCKDOWN[:username] &&
          password == SITE_LOCKDOWN[:password]
      end
    end
  end
  private :password_protect

  # only permit site members to add/delete things
  before_filter :login_required, only: [ :new, :create,
                                            :edit, :update, :destroy,
                                            :appearance, :homepage_options,
                                            :convert,
                                            :make_theme,
                                            :find_related,
                                            :link_related,
                                            :find_index,
                                            :flag_form,
                                            :flag_version,
                                            :restore,
                                            :reject,
                                            :choose_type, :render_item_form,
                                            :setup_rebuild,
                                            :rebuild_zoom_index,
                                            :add_portrait, :remove_portrait,
                                            :make_selected_portrait,
                                            :contact, :send_email,
                                            :join ]

  # doesn't work for redirects, those are handled by
  # after filters on registered on specific controllers
  # based on SystemSetting.allowed_anonymous_actions specs
  # this should prevent url surgery to subvert logging out of anonymous user though
  before_filter :logout_anonymous_user_unless_allowed, except: [:logout,
                                                                   :login,
                                                                   :signup,
                                                                   :show_captcha]

  # all topics and content items belong in a basket
  # and will always be specified in our routes
  before_filter :load_standard_baskets

  # sets up instance variables for authentication
  include KeteAuthorization

  before_filter :redirect_if_current_basket_isnt_approved_for_public_viewing

  # Create an instance variable with a list of baskets the
  # current user has roles in (member, admin etc)
  before_filter :update_basket_permissions_hash

  # keep track of tag_list input by version
  before_filter :update_params_with_raw_tag_list, only: [ :create, :update ]

  # see method definition for details

  # we often need baskets for edits
  before_filter :load_array_of_baskets, only: [ :edit, :update, :restore ]

  # don't allow forms to set do_not_moderate
  before_filter :security_check_of_do_not_moderate, only: [ :create, :update, :restore ]

  # set do_not_moderate if site_admin, otherwise things like moving from one basket to another
  # may get tripped up
  before_filter :set_do_not_moderate_if_site_admin_or_exempted, only: [ :create, :update ]

  # ensure that users who are in a basket where the action menu has been hidden can edit
  # by posting a dummy form
  before_filter :current_user_can_see_action_menu?, only: [:new, :create, :edit, :update]

  # TODO: NOT USED, delete code here and in lib/zoom_controller_helpers.rb
  # related items only track title and url, therefore only update will change those attributes
  after_filter :update_zoom_record_for_related_items, only: [ :update ]

  # setup return_to for the session
  # TODO: this needs to be updated to store location for newer actions
  # might be better to do an except?
  after_filter :store_location, only: [ :for, :all, :search, :index, :new, :show, :edit, :new_related_set_from_archive_file]

  # RSS feed related operations
  # no layout on rss pages
  layout :determine_layout
  def determine_layout
    params[:action] == 'rss' ? nil : 'application'
  end
  # adjust request and response values
  before_filter :adjust_http_headers_for_rss, only: [ :rss ]
  def adjust_http_headers_for_rss
    response.headers['Content-Type'] = 'application/xml; charset=utf-8'
    request.format = :xml
  end

  helper :slideshows
  helper :extended_fields

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
    @standard_basket_ids ||= Basket.standard_basket_ids

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
        @current_basket = Basket.where(urlified_name: params[:urlified_name]).first
      end
    end

    if @current_basket.nil?
      @current_basket = @site_basket
      # if were are already raising an error, don't call this again
      unless @displaying_error
        raise ActiveRecord::RecordNotFound, "Couldn't find Basket with NAME=#{params[:urlified_name]}."
      end
    end
  end

  # ROB:  item_from_controller_and_id() should probably be gotten-rid-of/clarrified along with
  #       prepare_item_and_vars(). #get_item

  # Walter McGinnis, 2008-09-29
  # adding security fix, so you can't see another basket's item's history
  # unless specifically allowed
  def item_from_controller_and_id(and_basket = true)
    if and_basket
      @current_basket.send(zoom_class_from_controller(params[:controller]).tableize).find(params[:id])
    else
      Module.class_eval(zoom_class_from_controller(params[:controller])).find(params[:id])
    end
  end

  # so we can transfer an item from one basket to another
  def load_array_of_baskets
    zoom_class = zoom_class_from_controller(params[:controller])
    if ZOOM_CLASSES.include?(zoom_class) and zoom_class != 'Comment'
      @baskets = Basket.all(order: 'name').map { |basket| [ basket.name, basket.id ] }
    end
  end

  def show_basket_list_naviation_menu?
    return false unless SystemSetting.is_configured
    return false if params[:controller] == 'baskets' && ['edit', 'appearance', 'homepage_options'].include?(params[:action])
    return false if params[:controller] == 'search'
    SystemSetting.uses_basket_list_navigation_menu_on_every_page?
  end

  def redirect_to_related_item(item, options={})
    redirect_to_show_for(item, options)
  end

  def update_zoom_and_related_caches_for(item, controller = nil)
    # refresh data for the item
    item = Module.class_eval(item.class.name).find(item)

    # item.prepare_and_save_to_zoom
    # use async backgroundrb process instead
    update_search_record_for(item)
  end

  def add_relation_and_update_zoom_and_related_caches_for(item1, item2)
    raise 'ERROR: Neither item 1 or 2 was a Topic' unless item1.is_a?(Topic) || item2.is_a?(Topic)
    topic, related = (item1.is_a?(Topic) ? [item1, item2] : [item2, item1])

    # clear out old zoom records before we change the items
    # sometimes zoom updates are confused and create a duplicate new record
    # instead of updating existing one
    # zoom_destroy_for(topic)
    # zoom_destroy_for(related)

    successful = ContentItemRelation.new_relation_to_topic(topic, related)

    update_zoom_and_related_caches_for(topic, zoom_class_controller(related.class.name))
    update_zoom_and_related_caches_for(related, ('topics' if related.is_a?(Topic)))

    return successful
  end

  def remove_relation_between(related_item: item1, topic: item2)
    raise 'ERROR: Neither topic is not a Topic' unless topic.is_a?(Topic)

    ContentItemRelation.destroy_relation_to_topic(topic, related_item)
  end

  def setup_related_topic_and_zoom_and_redirect(item, commented_item = nil, options = {})
    where_to_redirect = 'show_self'
    if !commented_item.nil? and @successful
      update_zoom_and_related_caches_for(commented_item)
      where_to_redirect = 'commentable'
    elsif !params[:relate_to_item].blank? and @successful
      @relate_to_item = params[:relate_to_type].constantize.find(params[:relate_to_item])
      add_relation_and_update_zoom_and_related_caches_for(@relate_to_item, item)

      # reset the related images slideshow if realted image was added
      session[:image_slideshow] = nil if item.is_a?(StillImage)

      where_to_redirect = 'show_related'
    elsif params[:is_theme] and item.class.name == 'Document' and @successful
      item.decompress_as_theme
      where_to_redirect = 'appearance'
    elsif params[:portrait] and item.class.name == 'StillImage' and @successful
      where_to_redirect = 'user_account'
    elsif params[:as_service].present? &&
        params[:as_service] == 'true' &&
        params[:service_target].present?
      where_to_redirect = 'service_target'
    end

    if @successful
      build_relations_from_topic_type_extended_field_choices
      update_zoom_and_related_caches_for(item)

      # send notifications of private item create
      private_item_notification_for(item, :created) if params[item.class_as_key][:private] == 'true'

      case where_to_redirect
      when 'show_related'
        # TODO: replace with translation stuff when we get globalize going
        flash[:notice] = t('application_controller.setup_related_topic_and_zoom_and_redirect.related_item', zoom_class: zoom_class_humanize(item.class.name))
        redirect_to_related_item(@relate_to_item, { private: (params[:related_item_private] && params[:related_item_private] == 'true' && permitted_to_view_private_items?) })
      when 'commentable'
        redirect_to_show_for(commented_item, options)
      when 'appearance'
        redirect_to action: :appearance, controller: 'baskets'
      when 'user_account'
        if params[:portrait] && params[:selected_portrait]
          flash[:notice] = t('application_controller.setup_related_topic_and_zoom_and_redirect.selected_portrait', zoom_class: zoom_class_humanize(item.class.name))
        elsif params[:portrait]
          flash[:notice] = t('application_controller.setup_related_topic_and_zoom_and_redirect.portrait', zoom_class: zoom_class_humanize(item.class.name))
        end
        redirect_to action: :show, controller: 'account', id: @current_user
      when 'service_target'
        service_target = params[:service_target]

        if params[:append_show_url].present? &&
            params[:append_show_url] == 'true'

          service_target += url_for_dc_identifier(item).sub('://', '%3A%2F%2F').gsub('/', '%2F')
        end
        redirect_to service_target
      else
        flash[:notice] = t('application_controller.setup_related_topic_and_zoom_and_redirect.created', zoom_class: zoom_class_humanize(item.class.name))
        redirect_to_show_for(item, options)
      end

    else
      render action: 'new'
    end
  end

  def link_related
    @related_to_item = params[:relate_to_type].constantize.find(params[:relate_to_item])

    unless params[:item].blank?
      for id in params[:item].reject { |k, v| v != 'true' }.collect { |k, v| k }
        item = only_valid_zoom_class(params[:related_class]).find(id)

        if params[:relate_to_type] == 'Topic' && params[:related_class] == 'Topic'
          @existing_relation = @related_to_item.related_topics.include?(item)
        else
          @existing_relation = @related_to_item.send(params[:related_class].tableize).include?(item)
        end

        if !@existing_relation
          @successful = add_relation_and_update_zoom_and_related_caches_for(item, @related_to_item)

          if @successful
            # in this context, the item being related needs updating, too
            update_zoom_and_related_caches_for(item)

            flash[:notice] = t('application_controller.link_related.added_relation')
          end
        end
      end
    end

    redirect_to controller: 'search', action: 'find_related',
                relate_to_item: params[:relate_to_item], relate_to_type: params[:relate_to_type],
                related_class: params[:related_class], function: 'remove'
  end

  def unlink_related
    @related_to_item = params[:relate_to_type].constantize.find(params[:relate_to_item])

    unless params[:item].blank?
      for id in params[:item].reject { |k, v| v != 'true' }.collect { |k, v| k }
        item = only_valid_zoom_class(params[:related_class]).find(id)

        remove_relation_between(related_item: item, topic: @related_to_item)

        flash[:notice] = t('application_controller.unlink_related.unlinked_relation')

      end
    end

    redirect_to controller: 'search', action: 'find_related',
                relate_to_item: params[:relate_to_item], relate_to_type: params[:relate_to_type],
                related_class: params[:related_class], function: 'remove'
  end

  # overriding here, to grab title of page, too
  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    # Because private files are served through a show action, this method gets called, but we
    # don't want to set the return_to url to a private image link
    return if params[:controller] == 'private_files'
    # this should prevent the same page from being added to return_to
    # but does not prevent case of differnt size images...
    session[:return_to] = request.original_fullpath
    session[:return_to_title] = @title
  end

  def redirect_to_search_for(zoom_class)
    redirect_to(controller: 'search',
                trailing_slash: true,
                action: :all,
                controller_name_for_zoom_class: zoom_class)
  end

  def redirect_to_default_all
    redirect_to list_basket_baskets_url('site')
    # redirect_to(basket_all_url(:controller_name_for_zoom_class => zoom_class_controller(SystemSetting.default_search_class)))
  end

  def redirect_to_all_for(controller)
    redirect_to list_basket_baskets_url('site')
    # redirect_to(basket_all_url(:controller_name_for_zoom_class => controller))
  end

  def redirect_to_show_for(item, options = {})
    redirect_to path_to_show_for(item, options)
  end

  def path_to_show_for(item, options = {})
    # By default, assume redirect to public version.
    options = {
      private: false
    }.merge(options)

    item = item.commentable if item.is_a?(Comment)

    path_hash = {
      urlified_name: item.basket.urlified_name,
      controller: zoom_class_controller(item.class.name),
      action: 'show',
      id: item,
      locale: false
    }

    # Redirect to private version if item is private.
    if options[:private]
      path_hash.merge!({ private: 'true' })
    end

    # Add the anchor if one is passed in
    if options[:anchor]
      path_hash.merge!({ anchor: options[:anchor] })
    end

    url_for(path_hash)
  end

  def render_oai_record_xml(options = {})
    item = options[:item]
    to_string = options[:to_string] || false
    if to_string
      item.oai_record
    else
      # :layout => false,
      render text: item.oai_record, content_type: 'text/xml'
    end
  end

  # TODO: this can likely be elimenated!
  # just use user.user_name
  def user_to_dc_creator_or_contributor(user)
    user.user_name
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

  def correct_url_for(item, version = nil)
    correct_action = version.nil? ? 'show' : 'preview'

    options = { action: correct_action, id: item }
    options[:version] = version if correct_action == 'preview'
    options[:private] = params[:private]

    item_url = nil
    if item.class.name == 'Comment' and correct_action != 'preview'
      commented_item = item.commentable
      item_url = url_for(controller: zoom_class_controller(commented_item.class.name),
                         action: correct_action,
                         id: commented_item,
                         anchor: item.id,
                         urlified_name: commented_item.basket.urlified_name)
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

    ZOOM_CLASSES.each do |zoom_class|
      # pending items aren't counted
      private_conditions = "title != '#{SystemSetting.blank_title}' "
      local_public_conditions = PUBLIC_CONDITIONS

      # comments are a special case
      # they have a subtly different data model that means they need an different condition
      if zoom_class == 'Comment'
        commentable_private_condition = ' AND commentable_private = ?'
        local_public_conditions = [local_public_conditions + commentable_private_condition, false]
        private_conditions = [private_conditions + commentable_private_condition, true]
      else
        private_conditions += 'AND private_version_serialized IS NOT NULL'
      end

      if basket == @site_basket
        @basket_stats_hash["#{zoom_class}_public"] = Module.class_eval(zoom_class).count(conditions: local_public_conditions)
      else
        @basket_stats_hash["#{zoom_class}_public"] = basket.send(zoom_class.tableize).count(conditions: local_public_conditions)
      end

      # Walter McGinnis, 2008-11-18
      # normally the site basket is a special case, in that is shows all items from all baskets
      # however in the context of private items, the rule is to show all private items that a USER has rights to see
      # so the counts may vary by user
      # because of caching, this becomes problematic to display counts for
      # so instead, we only show private items that are actually in the site basket
      # which happens to use the same code as other basket would, so we don't need to duplicate this at the moment
      # TODO: we will want to change this to match browsing of private items in site basket later
      if basket.show_privacy_controls_with_inheritance? && permitted_to_view_private_items?
        @basket_stats_hash["#{zoom_class}_private"] = basket.send(zoom_class.tableize).count(conditions: private_conditions)
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
          # zoom_destroy_for(comment)
          comment.basket = new_basket
          if comment.save
            # moving the comment adds a version
            comment.add_as_contributor(current_user)
          end
          # generate the new zoom record
          # with the new basket
          comment.prepare_and_save_to_zoom
        end
      end
    end
  end

  def after_successful_zoom_item_update(item, version_after_update)
    version_created = version_after_update ? item.versions.exists?(version: version_after_update) : false

    # if we need to add a contributor (sometimes, a version isn't
    # created if only timestamps were updated. In that case. we
    # don't want to add an incorrect contributor to the previous
    # version of the updated item)
    if version_created
      # James - 2008-12-21
      # Ensure the contribution is added against the latest version, not the current verrsion as it could
      # have been reverted automatically if full moderation is on for the basket.
        version = item.versions.order('version DESC').first.version

      # add this to the user's empire of contributions
      # TODO: allow current_user whom is at least moderator to pick another user
      # as contributor. uses virtual attr as hack to pass version to << method
      item.add_as_contributor(current_user, version)
    end

    # if the basket has been changed, make sure comments are moved, too
    update_comments_basket_for(item, @current_basket)

    # if changes to the item's extended content should add new relations
    build_relations_from_topic_type_extended_field_choices unless params[:controller] == 'search'

    # finally, sync up our search indexes

    # item.prepare_and_save_to_zoom if !item.already_at_blank_version?
    # switched to async backgroundrb worker version
    update_search_record_for(item) if !item.already_at_blank_version?

    # send notifications if needed
    item.do_notifications_if_pending(version_after_update, current_user) if version_created

    # send notifications of private item edit
    # do not do this when flagging, restoring, changing a homepage topic,
    # or converting a document into the description
    skipped_actions = ['flag_version', 'restore', 'find_index', 'convert']
    if !skipped_actions.include?(params[:action]) && params[item.class_as_key][:private] == 'true'
        private_item_notification_for(item, :edited)
    end
  end

  def history_url(item)
    # if we got sent a version object, we need to link to the latest version
    item = item.latest_version if item.class.name =~ /Version/

    url_for controller: zoom_class_controller(item.class.name), action: :history, id: item
  end

  # this is useful for creating a rss version of the request
  # or for replacing the page number in an existing rss url
  def derive_url_for_rss(options = { })
    replace_page_with_rss = !options[:replace_page_with_rss].nil? ? options[:replace_page_with_rss] : false

    page = !options.blank? && !options[:page].blank? ? options[:page] : nil

    # whether we replace normal page controller_name_for_zoom_class with 'combined'
    combined = options[:combined] || false

    url = request.protocol
    url += request.host_with_port

    # split everything before the query string and the query string
    url_parts = request.original_url.split('?')

    # now split the path up and add rss to it
    path_elements = url_parts[0].split('/')

    # replace topics, images, etc. with combined if called for
    if combined && !path_elements.include?('combined')
      # array of zoom class controllers
      CACHES_CONTROLLERS.each do |to_be_replaced|
        existing_index = path_elements.index(to_be_replaced)
        if existing_index
          path_elements.delete_at(existing_index)
          path_elements.insert(existing_index, 'combined')
        end
      end
    end

    # query string to hash
    query_parameters = request.query_parameters

    # delete the parameters that are artifacts from normal search
    %w( number_of_results_per_page tabindex sort_type sort_direction).each do |not_relevant|
      query_parameters.delete(not_relevant)
    end

    # also delete page, but only if this isn't already an rss request
    query_parameters.delete('page') unless path_elements.include?('rss.xml')

    # escape spaces in search terms
    query_parameters['search_terms'] = query_parameters['search_terms'].gsub(' ', '+') if query_parameters['search_terms']

    # if we need to take off index/list actions, do that here
    path_elements.pop if replace_page_with_rss

    # add rss.xml to it, if it doesn't already exist
    path_elements << 'rss.xml' unless path_elements.include?('rss.xml')

    new_path = path_elements.join('/')
    url +=  new_path

    query_parameters['page'] = page if page

    # if there is a query string, tack it on the end
    unless query_parameters.blank?
      formatted = query_parameters.collect { |k,v| k.to_s + '=' + v.to_s }
      url += '?' + formatted.join('&')
    end
    url
  end

  def rss_tag(options = { })
    auto_detect = !options[:auto_detect].nil? ? options[:auto_detect] : true

    tag = String.new
    tag += auto_detect ? '<link rel="alternate" type="application/rss+xml" title="RSS" ' : '<a '
    tag += 'href="' + derive_url_for_rss(options)
    tag +=  auto_detect ? '" />' : '" tabindex="1">' # A tag has a closing </a> in application layout
    tag
  end

  cattr_accessor :add_ons_full_width_content_wrapper_controllers, :add_ons_content_wrapper_end_controllers

  def self.add_ons_full_width_content_wrapper_controllers
    @@add_ons_full_width_content_wrapper_controllers || Array.new
  end

  def self.add_ons_content_wrapper_end_controllers
    @@add_ons_content_wrapper_end_controllers || Array.new
  end

  # override in your add-on by adding to corresponding class attribute
  # i.e ApplicationController.class_eval { self.add_ons_full_width_content_wrapper_controllers += ['your_controller'] }
  def add_ons_full_width_content_wrapper_controllers
    self.class.add_ons_full_width_content_wrapper_controllers
  end

  # i.e ApplicationController.class_eval { self.add_ons_full_width_content_wrapper_controllers += ['your_controller'] }
  def add_ons_content_wrapper_end_controllers
    self.class.add_ons_content_wrapper_end_controllers
  end

  def render_full_width_content_wrapper?
    if @displaying_error
      return false
    elsif params[:controller] == 'baskets' and ['edit', 'update', 'homepage_options', 'appearance'].include?(params[:action])
      return false
    elsif ['moderate', 'members', 'importers'].include?(params[:controller]) && ['list', 'create', 'new', 'new_related_set_from_archive_file', 'potential_new_members'].include?(params[:action])
      return false
    elsif params[:controller] == 'index_page' and params[:action] == 'index'
      return false
    elsif %w(tags search).include?(params[:controller])
      return false
    elsif add_ons_full_width_content_wrapper_controllers.include?(params[:controller])
      return true
    elsif params[:controller] == 'account' and params[:action] == 'show'
      return true
    elsif !['show', 'preview', 'show_private'].include?(params[:action])
      return true
    else
      return false
    end
  end

  def render_content_wrapper_end?
    return true if ACTIVE_SCAFFOLD_CONTROLLERS.include?(params[:controller])

    return true if add_ons_content_wrapper_end_controllers.include?(params[:controller])

    false
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
    item.respond_to?(:private) && item.private? ? 'true' : 'false'
  end

  def slideshow(key='slideshow')
    # Instantiate a new slideshow object on the slideshow session key
    session[key.to_sym] ||= HashWithIndifferentAccess.new
    Slideshow.new(session[key.to_sym])
  end

  def image_slideshow
    slideshow('image_slideshow')
  end

  # Append a query string to a URL.
  def append_options_to_url(url, options)
    options = options.join('&') if options.is_a?(Array)

    append_operator = url.include?('?') ? '&' : '?'
    url + append_operator + options
  end

  # ROB: I would like to get-rid-of/clarrify prepare_item_and_vars(). It feels like it should
  #      be something simpler in a controller. #get_item

  # setup a few variables that will be used on topic/audio/etc items
  def prepare_item_and_vars
    zoom_class = zoom_class_from_controller(params[:controller])
    if !ZOOM_CLASSES.member?(zoom_class)
      raise(ArgumentError, "zoom_class name expected. #{zoom_class} is not registered in #{ZOOM_CLASSES}.")
    end

    @current_item = @current_basket.send(zoom_class.tableize).find(params[:id])

    @show_privacy_chooser = true if permitted_to_view_private_items?

    if params[:format] == 'xml' || allowed_to_access_private_version_of?(@current_item)
      public_or_private_version_of(@current_item)
      privacy = get_acceptable_privacy_type_for(@current_item)

      if params[:format] == 'xml'
        @title = @current_item.title
      end

      if params[:format] == 'xml'
        @creator = @current_item.creator
        @last_contributor = @current_item.contributors.last || @creator
      end

      if logged_in? && @at_least_a_moderator
        if params[:format] == 'xml'
          @comments = @current_item.non_pending_comments
        end
      else
        if params[:format] == 'xml'
          @comments = @current_item.non_pending_comments
        end
      end
    end

    @current_item
  end

  # ROB:  WHy aren't using rails 404 page? Kill it. KILLLLL IIIITT! #custom_error_pages
  def rescue_404
    redirect_registration = RedirectRegistration.match(request).first
    unless redirect_registration
      @displaying_error = true
      @title = t('application_controller.rescue_404.title')
      render template: 'errors/error404', layout: 'application', status: '404'
    else
      redirect_to redirect_registration.new_url, status: redirect_registration.status_code
    end
  end

  # ROB:  see rescue_404() #custom_error_pages
  def rescue_500(template)
    @displaying_error = true
    @title = t('application_controller.rescue_500.title')
    render template: "errors/#{template}", layout: 'application', status: '500'
  end

  # ROB:  current_item() should probably be gotten-rid-of/clarrified along with
  #       prepare_item_and_vars(). #get_item
  def current_item
    @current_item ||= @audio_recording || @document || @still_image || @topic || @video || @web_link || nil
  end

  def current_sorting_options(default_order, default_direction, valid_orders = Array.new)
    @order = valid_orders.include?(params[:order]) ? params[:order] : default_order
    @direction = ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : default_direction
    "#{@order} #{@direction}"
  end

  def logout_anonymous
    if logged_in? &&
        current_user.anonymous?

      session[:anonymous_user] = nil

      current_user.reload

      deauthenticate
    end
  end

  def finished_as_anonymous_after
    logout_anonymous
  end

  # methods that should be available in views as well
  helper_method :prepare_short_summary, :history_url, :render_full_width_content_wrapper?, :render_content_wrapper_end?, :permitted_to_view_private_items?,
                :permitted_to_edit_current_item?, :allowed_to_access_private_version_of?, :accessing_private_search_and_allowed?,
                :get_acceptable_privacy_type_for, :current_user_can_see_contributors?, :current_user_can_see_add_links?,
                :current_user_can_add_or_request_basket?, :basket_policy_request_with_permissions?, :current_user_can_see_action_menu?,
                :current_user_can_see_discussion?, :current_user_can_see_private_files_for?, :current_user_can_see_private_files_in_basket?,
                :current_user_can_see_memberlist_for?, :show_attached_files_for?, :slideshow, :append_options_to_url, :current_item,
                :show_basket_list_naviation_menu?, :url_for_dc_identifier, :derive_url_for_rss, :show_notification_controls?, :path_to_show_for,
                :permitted_to_edit_basket_homepage_topic?, :current_user_can_import_archive_sets?, :current_user_can_import_archive_sets_for?, :anonymous_ok_for?

  # stub out methods to allow specs to run
  def auto_complete_for(*args); end

  protected

  def local_request?
    false
  end

  # ROB:  see rescue_404() #custom_error_pages
  def rescue_action_in_public(exception)
    @displaying_error = true

    # when an exception occurs, before filters arn't called, so we have to manually call them here
    # only call the ones absolutely nessesary (required settings, themes, permissions etc)
    load_standard_baskets
    redirect_if_current_basket_isnt_approved_for_public_viewing
    update_basket_permissions_hash

    case exception
    when ActionController::UnknownAction,
         ActiveRecord::RecordNotFound,
         ActiveRecord::RecordInvalid,
         ActionController::MethodNotAllowed then
      rescue_404
    when BackgrounDRb::NoServerAvailable then
      rescue_500('backgroundrb_connection_failed')
    when ActionController::InvalidAuthenticityToken then
      respond_to do |format|
        format.html { rescue_500('invalid_authenticity_token') }
        format.js { render file: File.join(Rails.root, 'app/views/errors/invalid_authenticity_token.js.rjs') }
      end
    else
      if exception.to_s.match(/Connect\ failed/)
        rescue_500('zebra_connection_failed')
      else
        respond_to do |format|
          format.html { rescue_500('error500') }
          format.js { render file: File.join(Rails.root, 'app/views/errors/error500.js.rjs') }
        end
      end
    end
  end

  private

  def redirect_if_current_basket_isnt_approved_for_public_viewing
    if @current_basket.status != 'approved' && !@site_admin && !@basket_admin
      flash[:error] = t('application_controller.redirect_if_current_basket_isnt_approved_for_public_viewing.not_available',
                        basket_name: @current_basket.name)
      redirect_to "/#{@site_basket.urlified_name}"
    end
  end

  def logout_anonymous_user_unless_allowed
    if !anonymous_ok_for?(request.path)
      logout_anonymous
    end
  end

  def item_controllers
    @item_controllers ||= ITEM_CLASSES.collect { |c| zoom_class_controller(c) }
  end
end
