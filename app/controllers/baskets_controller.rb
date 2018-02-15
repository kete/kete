# frozen_string_literal: true

class BasketsController < ApplicationController
  permit 'site_admin or admin of :current_basket', only: %i[
    edit update homepage_options destroy
    add_index_topic appearance update_appearance
    set_settings]

  before_filter :redirect_if_current_user_cant_add_or_request_basket, only: %i[new create]

  after_filter :remove_robots_txt_cache, only: %i[create update destroy]

  # Get the Privacy Controls helper for the add item forms
  helper :privacy_controls

  include EmailController

  include WorkerControllerHelpers

  # include TaggingController

  include AnonymousFinishedAfterFilter

  def index
    redirect_to action: 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # EOIN: FIXME: verify is not in rails3 but we do need to limit the HTTP verbs in routing. This will need to be addressed before we go live
  # verify :method => :post, :only => [ :destroy, :create, :update ],
  #        :redirect_to => { :action => :list }

  def list
    list_baskets

    @rss_tag_auto = rss_tag(replace_page_with_rss: true)
    @rss_tag_link = rss_tag(replace_page_with_rss: true, auto_detect: false)

    @requested_count = Basket.count(conditions: "status = 'requested'")
    @rejected_count = Basket.count(conditions: "status = 'rejected'")
  end

  def rss
    @number_per_page = 100
    @baskets = Basket.all(limit: @number_per_page, order: 'id DESC')

    respond_to do |format|
      format.xml
    end
  end

  def show
    redirect_to_default_all
  end

  def new
    @profiles = Profile.all
    params[:basket_profile] = @profiles.first.id if @profiles.size == 1
    @basket = Basket.new
    prepare_and_validate_profile_for(:edit)
  end

  def render_basket_form
    new
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace_html 'basket_form', partial: 'new_form'
        end
      end
    end
  end

  def create
    convert_text_fields_to_boolean

    # if an site admin makes a basket, make sure the basket is instantly approved
    params[:basket][:status] =
      if basket_policy_request_with_permissions?
        'requested'
      else
        'approved'
                                    end

    params[:basket][:creator_id] = current_user.id

    @basket = Basket.new(params[:basket])
    @profiles = Profile.all
    prepare_and_validate_profile_for(:edit)

    if @basket.save
      # Reload to ensure basket.creator is updated.
      @basket.reload

      set_settings

      # Set this baskets profile mapping
      if params[:basket_profile]
        profile = Profile.find_by_id(params[:basket_profile])
        @basket.profiles << profile if profile
      end

      # if basket creator is admin or creation not moderated, make creator basket admin
      @basket.accepts_role('admin', current_user) if SystemSetting.basket_creation_policy == 'open' || @site_admin

      # if an site admin makes a basket, make sure emailing notifications are skipped
      if basket_policy_request_with_permissions?
        @site_basket.administrators.each do |administrator|
          UserNotifier.basket_notification_to(administrator, current_user, @basket, 'request').deliver
        end
        flash[:notice] = t('baskets_controller.create.to_be_reviewed')
        redirect_to "/#{@site_basket.urlified_name}"
      else
        unless @site_admin
          @site_basket.administrators.each do |administrator|
            UserNotifier.basket_notification_to(administrator, current_user, @basket, 'created').deliver
          end
        end
        flash[:notice] = t('baskets_controller.create.created')
        redirect_to urlified_name: @basket.urlified_name, controller: 'baskets', action: 'edit', id: @basket
      end
    else
      render action: 'new'
    end
  end

  def edit
    appropriate_basket
    @topics = @basket.topics
    @index_topic = @basket.index_topic
    prepare_and_validate_profile_for(:edit)
  end

  def homepage_options
    appropriate_basket
    @topics = @basket.topics
    @index_topic = @basket.index_topic
    prepare_and_validate_profile_for(:homepage_options)
  end

  def update
    params[:source_form] ||= 'edit'
    params[:basket] ||= {}

    @basket = Basket.find(params[:id])
    @topics = @basket.topics
    original_name = @basket.name

    unless params[:accept_basket].blank?
      params[:basket][:status] = 'approved'
      @basket.accepts_role('admin', @basket.creator)
    end

    params[:basket][:status] = 'rejected' unless params[:reject_basket].blank?

    # have to update zoom records for things in the basket
    # in two steps
    # delete old record before basket.urlified_name has changed
    # as well as caches
    # because item.zoom_destroy needs original record to match
    # then after update, create new zoom records with new urlified_name
    if !params[:basket][:name].blank? && (original_name != params[:basket][:name])
      ZOOM_CLASSES.each do |zoom_class|
        basket_items = @basket.send(zoom_class.tableize)
        basket_items.each do |item|
          zoom_destroy_for(item)
        end
      end
    end

    # Because we dont edit the basket content on edit form, skip sanitizing the content
    # to prevent changes in edit from being locked out
    params[:basket][:do_not_sanitize] = true if params[:source_form] == 'edit'

    convert_text_fields_to_boolean if params[:source_form] == 'edit'

    prepare_and_validate_profile_for(params[:source_form].to_sym)

    # clear out existing feeds before looping over the new set
    # it is important this only run if the source form was the homepage options
    @basket.feeds.destroy_all if params[:source_form].to_sym == :homepage_options

    if @basket.update_attributes(params[:basket])
      # Reload to ensure basket.name is updated and not the previous
      # basket name.
      @basket.reload

      set_settings

      # clear slideshow in session
      # in case the user user changes how images should be ordered
      session[:slideshow] = nil
      session[:image_slideshow] = nil

      # @basket.name has changed
      if original_name != @basket.name
        # update zoom records for basket items
        # to match new basket.urlified_name
        ZOOM_CLASSES.each do |zoom_class|
          basket_items = @basket.send(zoom_class.tableize)
          basket_items.each do |item|
            # item.prepare_and_save_to_zoom
            # switched to async backgroundrb worker for search record set up
            update_search_record_for(item)
          end
        end
      end

      # We send the emails right before a redirect so
      # it doesn't break anything if the emailing fails
      unless params[:accept_basket].blank?
        UserNotifier.basket_notification_to(@basket.creator, current_user, @basket, 'approved').deliver
      end
      unless params[:reject_basket].blank?
        UserNotifier.basket_notification_to(@basket.creator, current_user, @basket, 'rejected').deliver
      end

      # Add this last because it takes the longest time to process
      @basket.feeds.each do |feed|
        feed.update_feed
        MiddleMan.new_worker(worker: :feeds_worker, worker_key: feed.to_worker_key, data: feed.id)
      end

      flash[:notice] = t('baskets_controller.update.updated')
      redirect_to "/#{@basket.urlified_name}/"
    else
      render action: params[:source_form]
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
        if !zoom_items.empty?
          zoom_items.each do |item|
            @successful = zoom_item_destroy(item)
            break unless @successful
          end
        else
          @successful = true
        end
      end
      break unless @successful
    end

    @successful = @basket.destroy if @successful

    if @successful
      flash[:notice] = t('baskets_controller.destroy.destroyed')
      redirect_to '/'
    end
  end

  def add_index_topic
    @topic = Topic.find(params[:topic])
    @basket = Basket.find(params[:index_for_basket])
    @successful = @basket.update_index_topic(@topic)
    if @successful
      # this action saves a new version of the topic
      # add this as a contribution
      @topic.add_as_contributor(current_user)
      flash[:notice] = t('baskets_controller.add_index_topic.created')
      if params[:return_to_homepage]
        redirect_to "/#{@basket.urlified_name}"
      else
        redirect_to action: 'homepage_options', controller: 'baskets', id: params[:index_for_basket]
      end
    end
  end

  def appearance
    appropriate_basket
    prepare_and_validate_profile_for(:appearance)
  end

  def update_appearance
    @basket = Basket.find(params[:id])
    do_not_sanitize = (params[:settings][:do_not_sanitize_footer_content] == 'true')
    original_html = params[:settings][:additional_footer_content]
    sanitized_html = original_html
    unless do_not_sanitize && @site_admin || original_html.blank?
      sanitized_html = original_html.sanitize
      params[:settings][:additional_footer_content] = sanitized_html
    end
    prepare_and_validate_profile_for(:appearance)
    set_settings
    flash[:notice] = t('baskets_controller.update_appearance.updated')
    logger.debug('sanitized yes') if original_html != sanitized_html
    flash[:notice] += t('baskets_controller.update_appearance.sanitized') if original_html != sanitized_html
    redirect_to action: :appearance
  end

  def choose_type
    # give the user the option to add the item to any place the have access to
    @basket_list = []
    if @site_admin
      @basket_list = Basket.list_as_names_and_urlified_names
    else
      all_baskets_hash = {}
      # get the add item setting for each of the baskets the user has access to
      Basket.find_all_by_urlified_name(@basket_access_hash.stringify_keys.keys).each do |b|
        all_baskets_hash[b.urlified_name.to_sym] = { basket: b, privacy: b.setting(:show_add_links) }
      end
      # collect baskets that they can see add item controls for
      @basket_list = @basket_access_hash.collect do |basket_urlified_name, basket_hash|
        current_user_is?(all_baskets_hash[basket_urlified_name.to_sym][:privacy], all_baskets_hash[basket_urlified_name.to_sym][:basket]) \
          ? [basket_hash[:basket_name], basket_urlified_name.to_s] \
          : nil
      end.compact
    end

    @item_types = []
    ZOOM_CLASSES.each do |zoom_class|
      if zoom_class != 'Comment'
        @item_types << [
          zoom_class_humanize(zoom_class),
          zoom_class_controller(zoom_class)]
      end
    end

    return unless request.post?

    redirect_to urlified_name: params[:new_item_basket],
                controller: params[:new_item_controller],
                action: 'new',
                relate_to_item: params[:relate_to_item],
                relate_to_type: params[:relate_to_type],
                related_item_private: params[:related_item_private]
  end

  def render_item_form
    @new_item_basket = params[:new_item_basket]
    @new_item_controller = params[:new_item_controller]
    @relate_to_item = params[:relate_to_item]
    @relate_to_type = params[:relate_to_type]
    @related_item_private = params[:related_item_private]
    params[:topic] = {}
    params[:topic][:topic_type_id] = params[:new_item_topic_type]

    @item_class = zoom_class_from_controller(@new_item_controller)
    @item = @item_class.constantize.new
    @content_type = ContentType.find_by_class_name(@item_class)

    respond_to do |format|
      format.html { render partial: 'topics/form', layout: 'application' }
      format.js
    end
  end

  # the start of a page
  # where the user is told they don't have access to requested action
  # and they are presented with options to continue
  # in the future this will present the join policy of the basket, etc
  # now it only says "login as different user or contact an administrator"
  def permission_denied; end

  def set_settings
    return unless params[:settings]

    # create a hash with setting keys and values for usage later
    basket_settings = {}
    @basket.settings.each_with_key { |key, value| basket_settings[key.to_sym] = value }

    params[:settings].each do |name, value|
      # make sure we do not cause an SQL query if the value is the same
      next if basket_settings[name.to_sym] == value
      # convert the string to a boolean/nil value if it can be
      value = value.param_to_obj_equiv if value.is_a?(String)
      # save this new value to the baskets settings
      @basket.settings[name] = value
    end
  end

  def appropriate_basket
    @basket = current_basket_is_selected? ? @current_basket : Basket.find(params[:id])
  end

  def current_basket_is_selected?
    params[:id].blank? || @current_basket.id == params[:id]
  end

  # make these methods available in the views
  helper_method :profile_rules, :allowed_field?, :current_value_of

  private

  #
  # Basket Profile Helpers
  # (we put them in the controller because some are used here)
  #

  # when we are making/editing a basket, set the default values so they
  # reflect on the form the person making the basket sees. Don't do this
  # however if they have submitted a form and a value exists in params[:basket]
  # (because it overwrites it)
  # we can't use hidden fields because its not secure
  # so after a post has been made, we have to check values
  # are allowed/set and replace/add them if they aren't.
  # make sure we edit the params hash for both basket and settings
  # as well as the @basket object for basket settings
  # don't do this if the user is a site admin though
  def prepare_and_validate_profile_for(form_type)
    # this var is used in form helpers
    @form_type = form_type

    # we don't run this method is we don't have profile rules
    return if profile_rules.blank?

    # we need to check all form types for the values
    form_types = %i[edit appearance homepage_options]

    # make the params values hash if they aren't already
    params[:basket] ||= {}
    params[:settings] ||= {}

    Rails.logger.debug 'Before params validation and reset, basket was ' + params[:basket].inspect
    Rails.logger.debug 'Before params validation and reset, settings was ' + params[:settings].inspect

    # for each basket attribute, reset to the default value if not an allowed field
    Basket::EDITABLE_ATTRIBUTES.each do |setting|
      if (@site_admin || allowed_field?(setting)) && params[:basket].key?(setting.to_sym)
        # if we run this, it means that the current user is allowed
        # to set this field and the field has a value already
        @basket.send("#{setting}=", params[:basket][setting.to_sym])
      else
        # if we run this, it means that the current user is not allowed
        # to set this field, or they are but the field has no value
        value = current_value_of(setting, true, form_types)
        next if setting.to_sym == :feeds_attributes && value.nil?
        params[:basket][setting.to_sym] = value
        @basket.send("#{setting}=", value)
      end
    end

    # for each basket setting, reset to the default value if not an allowed field
    Basket::EDITABLE_SETTINGS.each do |setting|
      next unless !(@site_admin || allowed_field?(setting)) && !params[:basket].key?(setting.to_sym)
      # if we run this, it means that the current user is not allowed
      # to set this field, or they are but the field has no value
      params[:settings][setting.to_sym] = current_value_of(setting, true, form_types)
    end

    Rails.logger.debug 'After params validation and reset, basket is ' + params[:basket].inspect
    Rails.logger.debug 'After params validation and reset, settings is ' + params[:settings].inspect
  end

  # gets the profile rules for this basket. Memoize the result to prevent needless queries
  # in the case of a new record, pull the basket profile from the db based on
  # basket_profile param. In the case of editing a record, pull the first basket profile
  # from the associations. In either case, if a profile doesn't exist or can't be found,
  # return nil.
  def profile_rules
    @profile_rules ||=
      begin
           if !@basket || @basket.new_record?
             profile = Profile.find_by_id(params[:basket_profile])
             profile ? profile.rules(true) : nil
           else
             !@basket.profiles.blank? ? @basket.profiles.first.rules(true) : nil
           end
         end
  end

  # Check whether a field is allowed to be shown to a user
  # return true if no profiles are mapped to this basket
  # return true if the profiles rule type is all
  # Some fields exists as child options of a parent option, and as such,
  # don't have their checkboxes, and thus arn't in the allowed list, however
  # if this method is being called for them, then the parent has been allowed
  # so return true if the field is in any of the child/nested fields. We have
  # to do this before anything that returns false else they get turned to nil
  # return false if the profiles rule type is none
  # return true if the field is in the profiles allowed field list
  # finally, return false
  def allowed_field?(name)
    return true if profile_rules.blank? # no profile mapping
    return true if params[:show_all_fields] && @site_admin
    return true if profile_rules[@form_type.to_s]['rule_type'] == 'all'
    return true if Basket::NESTED_FIELDS.include?(name)
    return false if profile_rules[@form_type.to_s]['rule_type'] == 'none'
    return true if profile_rules[@form_type.to_s]['allowed'] &&
                   profile_rules[@form_type.to_s]['allowed'].include?(name.to_s)
    false
  end

  # get the current value of a field, from either basket/setting submitted values,
  # profile if new record, or exsiting value of existing record
  # skip_posted_values will skip getting the value from params
  def current_value_of(name, skip_posted_values = false, form_type = nil)
    form_type ||= @form_type

    value = nil

    unless skip_posted_values
      # if the value exists in a submitted form, use it
      value = params[:basket][name] if params[:basket] && params[:basket].key?(name)
      value = params[:settings][name] if params[:settings] && params[:settings].key?(name)
    end

    if value.nil? && @basket && !@basket.new_record?
      value =
        if @basket.respond_to?(name)
          # if the basket responds to a value method
          @basket.send(name)
        elsif @basket.respond_to?("#{name}?")
          # if the basket respond to a boolean method
          @basket.send("#{name}?")
        else
          # else, see if it has a setting (which will returns nil if not)
          @basket.settings[name.to_sym]
                     end
    end

    # if by this point we still have nothing/nil
    if value.nil? || value.class == NilClass
      if profile_rules.blank?
        # no profile mapping
        value = nil
      else
        # return the profile rule default value
        # if we have an array, loop through them all, checking all types for an ok field
        if form_type.is_a?(Array)
          form_type.each do |type|
            next unless profile_rules[type.to_s] && profile_rules[type.to_s]['values']
            value ||= profile_rules[type.to_s]['values'][name.to_s]
          end
        else
          value = profile_rules[form_type.to_s]['values'][name.to_s]
        end
      end
    end

    # turn strings into booleans when possible for comparing (v == false) etc
    case value
    when 'true'
      true
    when 'false'
      false
    when 'nil', 'inherit'
      nil
    else
      value
    end
  end

  #
  # End of Basket Profile Helpers
  #

  def list_baskets(per_page = 10)
    @listing_type =
      if !params[:type].blank? && @site_admin
        params[:type]
      else
        'approved'
                         end

    @default_sorting = { order: 'created_at', direction: 'desc' }
    paginate_order = current_sorting_options(
      @default_sorting[:order],
      @default_sorting[:direction], %w[name created_at]
    )

    options = { 
      page: params[:page],
      per_page: per_page,
      order: paginate_order 
    }
    options[:conditions] = ['status = ?', @listing_type]

    @baskets = Basket.paginate(options)
  end

  # Kieran Pilkington, 2008/08/26
  # In order to set settings back to inherit, we have to take strings
  # and convert back to booleans or nil later. We have to take boolean
  # as well though, as they are used in functional tests
  def convert_text_fields_to_boolean
    boolean_fields = %i[show_privacy_controls private_default file_private_default allow_non_member_comments]
    boolean_fields.each do |field|
      params[:basket][field] =
        case params[:basket][field]
        when 'true', true
          true
        when 'false', false
          false
                                      end
    end
  end

  # Kieran Pilkington, 2008/10/01
  # When a basket is created, edited, or deleted, we have to clear
  # the robots txt file caches to the new settings take effect
  def remove_robots_txt_cache
    expire_page '/robots.txt'
  end

  # Kieran Pilkington - 2008/09/22
  # redirect to permission denied if current user cant add/request baskets
  def redirect_if_current_user_cant_add_or_request_basket
    unless current_user_can_add_or_request_basket?
      flash[:error] = t('baskets_controller.redirect_if_current_user_cant_add_or_request_basket.not_authorized')
      redirect_to DEFAULT_REDIRECTION_HASH
    end
  end
end
