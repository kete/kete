module KeteAuthorisationSettings
  # ROB:  This could possibly be a helper rather than a model.

  # ROB:  We're going to switch from Kete's custom login system to devise.
  #
  #       Here's a nice place to dump code in the existing system that might
  #       be needed.
  #
  #       Probably these will be from app/controllers/application_controller.rb
  #       and lib/kete_authorization.rb.

  def basket_policy_request_with_permissions?
    SystemSetting.basket_creation_policy == 'request' && !@site_admin
  end

  # Walter McGinnis, 2006-04-03
  # bug fix for when site admin moves an item from one basket to another
  # if params[:topic][basket_id] exists and site admin
  # set do_not_moderate to true
  # James - Also allows for versions of an item modified my a moderator due to insufficient content to bypass moderation
  def set_do_not_moderate_if_site_admin_or_exempted
    item_class = zoom_class_from_controller(params[:controller])
    item_class_for_param_key = item_class.tableize.singularize
    if ZOOM_CLASSES.include?(item_class)
      if !params[item_class_for_param_key].nil? && @site_admin
        params[item_class_for_param_key][:do_not_moderate] = true

      # James - Allow an item to be exempted from moderation - this allows for items that have been edited by a moderator prior to
      # acceptance or reversion to be passed through without needing a second moderation pass.
      # Only applicable usage can be found in lib/flagging_controller.rb line 93 (also see 2x methods below).
      elsif !params[item_class_for_param_key].nil? && exempt_from_moderation?(params[:id], item_class)
        params[item_class_for_param_key][:do_not_moderate] = true

      elsif !params[item_class_for_param_key].nil? && !params[item_class_for_param_key][:do_not_moderate].nil?
        params[item_class_for_param_key][:do_not_moderate] = false
      end
    end
  end

  # James - Allow us to flag a version as except from moderation
  def exempt_next_version_from_moderation!(item)
    session[:moderation_exempt_item] = {
      item_class_name: item.class.name,
      item_id: item.id.to_s
    }
  end

  # James - Find whether an item is exempt from moderation. Used in #set_do_not_moderate_if_site_admin_or_exempted
  # Note that this can only be used once, so when this is called, the exemption on the item is cleared and future versions will
  # be moderated if full moderation is turned on.
  def exempt_from_moderation?(item_id, item_class_name)
    key = session[:moderation_exempt_item]
    return false if key.blank?

    result = (item_class_name == key[:item_class_name] && item_id.to_s.split('-').first == key[:item_id])

    session[:moderation_exempt_item] = nil

    result
  end

  def security_check_of_do_not_moderate
    item_class = zoom_class_from_controller(params[:controller])
    item_class_for_param_key = item_class.tableize.singularize
    if ZOOM_CLASSES.include?(item_class) && !params[item_class_for_param_key].nil? && !params[item_class_for_param_key][:do_not_moderate].nil?
      params[item_class_for_param_key][:do_not_moderate] = false if !@site_admin
    end
  end

  def current_user_can_see_action_menu?
    current_user_is?(@current_basket.setting(:show_action_menu))
  end

  def current_user_can_see_discussion?
    current_user_is?(@current_basket.setting(:show_discussion))
  end

  # Specific test for private file visibility.
  # If the user is a site admin, the file isn't private,
  # or they have permissions then return true
  def current_user_can_see_private_files_for?(item)
    @site_admin || !item.file_private? || current_user_can_see_private_files_in_basket?(item.basket)
  end

  # Test for private file visibility in a given basket
  def current_user_can_see_private_files_in_basket?(basket)
    current_user_is?(basket.private_file_visibility_with_inheritance)
  end

  # Test for memberlist visibility in a given basket
  def current_user_can_see_memberlist_for?(basket)
    current_user_is?(basket.memberlist_policy_with_inheritance, basket)
  end

  # Test for import archive set visibility for the given user in the current basket
  def current_user_can_import_archive_sets_for?(basket = @current_basket)
    current_user_is?(basket.import_archive_set_policy_with_inheritance, basket)
  end
  alias current_user_can_import_archive_sets? current_user_can_import_archive_sets_for?

  def current_user_can_see_contributors?
    # ROB:  Was previously current_user_can_see_flagging?(). Hiding the contributors
    #       lumped with flagging makes less sense.
    true
  end

  def current_user_can_see_add_links?
    current_user_is?(@current_basket.setting(:show_add_links))
  end

  def current_user_can_add_or_request_basket?
    return false unless logged_in?
    return true if @site_admin
    case SystemSetting.basket_creation_policy
    when 'open', 'request'
      true
    else
      false
    end
  end

  # check to see if url is something that can be done anonymously
  def anonymous_ok_for?(url)
    return false unless url.present? && SystemSetting.is_configured? &&
                        SystemSetting.allowed_anonymous_actions.present? &&
                        SystemSetting.allowed_anonymous_actions.size > 0

    # get controller and action from url
    # strip off query string before submitting to routing
    url = url.split('?')[0]
    from_url = String.new
    begin
      from_url = ActionController::Routing::Routes.recognize_path(url, method: :get)
    rescue
      from_url = ActionController::Routing::Routes.recognize_path(url, method: :post)
    end
    value = from_url[:controller] + '/' + from_url[:action]

    # check if it is an allowed for or finished after controller/action combo
    SystemSetting.allowed_anonymous_actions.collect { |h| h.values }.flatten.include?(value)
  end

  def public_or_private_version_of(item)
    if allowed_to_access_private_version_of?(item)
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
                                         permit?('site_admin or moderator of :current_basket or member of :current_basket or admin of :current_basket')
  end
  alias permitted_to_edit_current_item? permitted_to_view_private_items?

  def permitted_to_edit_basket_homepage_topic?
    @permitted_to_edit_basket_homepage_topic ||= logged_in? &&
                                                 permit?('site_admin of :site_basket or admin of :site_basket')
  end

  # checks if the user is requesting a private version of an item, and see
  # if they are allowed to do so
  def allowed_to_access_private_version_of?(item)
    return false unless item.nil? || item.has_private_version?
    (!params[:private].nil? && params[:private] == 'true' && permitted_to_view_private_items?)
  end

  # checks if the user is requesting a private search of a basket, and see
  # if they are allowed to do so
  def accessing_private_search_and_allowed?
    (!params[:privacy_type].nil? and params[:privacy_type] == 'private' and permitted_to_view_private_items?)
  end

  # used to get the acceptable privacy type (that is the current requested
  # privacy type unless not allowed), and return a value
  # (used in caching to decide whether to look for public or private fragments)
  def get_acceptable_privacy_type_for(item, value_when_public = 'public', value_when_private = 'private')
    if allowed_to_access_private_version_of?(item)
      value_when_private
    else
      value_when_public
    end
  end

  def show_notification_controls?(basket = @current_basket)
    return false if basket.setting(:private_item_notification).blank?
    return false if basket.setting(:private_item_notification) == 'do_not_email'
    return false unless basket.show_privacy_controls_with_inheritance?
    true
  end

  def private_item_notification_for(item, type)
    return if item.skip_email_notification == '1'
    return unless show_notification_controls?(item.basket)

    url_options = { private: true }

    if item.is_a?(Comment)
      email_type = 'comment'
      url_options[:anchor] = item.to_anchor
    else
      email_type = 'item'
    end

    # send notifications of private item
    item.basket.users_to_notify_of_private_item.each do |user|
      next if user == current_user
      case type
      when :created
        UserNotifier.send("private_#{email_type}_created", user, item, path_to_show_for(item, url_options)).deliver
      when :edited
        UserNotifier.send("private_#{email_type}_edited", user, item, path_to_show_for(item, url_options)).deliver
      end
    end
  end

  private

  def update_basket_permissions_hash
    @basket_access_hash = logged_in? ? current_user.basket_permissions : Hash.new
  end

  def current_user_is?(at_least_setting, basket = @current_basket)
    # everyone can see, just return true
    return true if at_least_setting == 'all users' || at_least_setting.blank?

    # all other settings, you must be at least logged in
    return false unless logged_in?

    # do we just want people logged in?
    return true if at_least_setting == 'logged in'

    # finally, if they are logged in
    # we evaluate matching instance variable if they have the role that matches
    # our basket setting

    # if we are checking at least settings on a different basket, we have to
    # populate new ones with the context of that basket, not the current basket
    if basket != @current_basket
      load_at_least(basket)
      instance_variable_get("@#{at_least_setting.tr(" ", "_")}_of_specified_basket")
    else
      instance_variable_get("@#{at_least_setting.tr(" ", "_")}")
    end
  rescue
    raise "Unknown authentication type: #{$!}"
  end
end
