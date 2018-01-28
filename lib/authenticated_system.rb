module AuthenticatedSystem
  protected

  def deauthenticate
    current_user.forget_me if logged_in?
    cookies.delete :auth_token
    # Walter McGinnis, 2008-03-16
    # added to support brain_buster plugin captcha
    cookies.delete :captcha_status
    reset_session
  end

  # Returns true or false if the user is logged in.
  # Preloads @current_user with the user model if they're logged in.
  def logged_in?
    current_user != :false
  end

  # Accesses the current user from the session.
  def current_user
    # @current_user ||= (session[:user] && User.find_by_id(session[:user])) || :false
    unless @current_user
      # maybe_user will be nil if session[:user] does not exist or we fail to find the User in the DB
      maybe_user = User.find_by_id(session[:user])
      @current_user = (maybe_user.nil? ? :false : maybe_user)
    end

    if @current_user != :false && @current_user.anonymous? && session[:anonymous_user].present?
      if session[:anonymous_user][:email].present?
        @current_user.email = session[:anonymous_user][:email]
      end

      if session[:anonymous_user][:name].present?
        @current_user.resolved_name = session[:anonymous_user][:name]
      end

      if session[:anonymous_user][:website].present?
        @current_user.website = session[:anonymous_user][:website]
      end
    end

    @current_user
  end

  # Store the given user in the session.
  def current_user=(new_user)
    session[:user] = new_user.nil? || new_user.is_a?(Symbol) ? nil : new_user.id
    @current_user = new_user
  end

  # Check if the user is authorized.
  #
  # Override this method in your controllers if you want to restrict access
  # to only a few actions or if you want to check if the user
  # has the correct rights.
  #
  # Example:
  #
  #  # only allow nonbobs
  #  def authorize?
  #    current_user.login != "bob"
  #  end
  def authorized?
    true
  end

  # Filter method to enforce a login requirement.
  #
  # To require logins for all actions, use this in your controllers:
  #
  #   before_filter :login_required
  #
  # To require logins for specific actions, use this in your controllers:
  #
  #   before_filter :login_required, :only => [ :edit, :update ]
  #
  # To skip this in a subclassed controller:
  #
  #   skip_before_filter :login_required
  #
  def login_required
    # Walter McGinnis, 2007-12-12
    # adding support for rss authentication
    # via rails 2.0 http_basic_authentication
    user = nil
    have_auth_data = false
    case request.format
    when Mime::XML, Mime::ATOM
      if user = authenticate_with_http_basic { |u, p| User.authenticate(u, p) }
        have_auth_data = true
        self.current_user = user
      end
    else
      username, passwd = get_auth_data
      user = User.authenticate(username, passwd)
      have_auth_data = true if username && passwd
    end
    if have_auth_data
      if user.nil?
        self.current_user ||= :false
      else
        self.current_user ||= user
      end
    end
    logged_in? && authorized? ? true : access_denied
  end

  # Redirect as appropriate when an access request fails.
  #
  # The default action is to redirect to the login screen.
  #
  # Override this method in your controllers if you want to have special
  # behavior in case the user is not authorized
  # to access the requested action.  For example, a popup window might
  # simply close itself.
  def access_denied
    respond_to do |accepts|
      accepts.html do
        store_location

        flash[:notice] = I18n.t('authenticated_system_lib.access_denied.please')

        if anonymous_ok_for?(session[:return_to])
          flash[:notice] += I18n.t('authenticated_system_lib.access_denied.enter_your_details')
        end

        flash[:notice] += I18n.t('authenticated_system_lib.access_denied.login')

        flash[:notice] += I18n.t('authenticated_system_lib.access_denied.before_proceeding')

        redirect_to urlified_name: Basket.site_basket.urlified_name,
                    controller: 'account',
                    action: 'login'
      end
      accepts.xml do
        if user = authenticate_or_request_with_http_basic { |u, p| User.authenticate(u, p) }
          self.current_user = user
          if logged_in? and authorized?
            return true
          end
        end
      end
    end
    false
  end

  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.original_url
  end

  # Strip the locale out of the URL
  # If a hash, sets locale to false
  # If a string, gsubs it out
  def strip_locale(hash_or_url)
    if hash_or_url.is_a?(Hash)
      hash_or_url[:locale] = false
    elsif hash_or_url.is_a?(String)
      locale_match = %r(^/(#{I18n.available_locales_with_labels.keys.map { |l| l.to_s }.join('|')}))
      hash_or_url = hash_or_url.gsub(locale_match, '')
      hash_or_url
    else
      raise "ERROR: Don't know how to strip locale from #{hash_or_url.class.name}"
    end
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.
  def redirect_back_or_default(default, lang = nil)
    if session[:return_to]
      return_to = strip_locale(session[:return_to])
      return_to = "/#{lang}" + return_to if lang
      redirect_to(return_to)
    else
      redirect_to(default)
    end
    session[:return_to] = nil
  end

  # Inclusion hook to make #current_user and #logged_in?
  # available as ActionView helper methods.
  def self.included(base)
    base.send :helper_method, :current_user, :logged_in?
  end

  # When called with before_filter :login_from_cookie will check for an :auth_token
  # cookie and log the user back in if apropriate
  def login_from_cookie
    return unless cookies[:auth_token] && !logged_in?
    user = User.find_by_remember_token(cookies[:auth_token])
    if user && user.remember_token?
      user.remember_me
      self.current_user = user
      cookies[:auth_token] = { value: self.current_user.remember_token, expires: self.current_user.remember_token_expires_at }
      flash[:notice] = I18n.t('authenticated_system_lib.login_from_cookie.logged_in')
    end
  end

  private

  @@http_auth_headers = %w(X-HTTP_AUTHORIZATION HTTP_AUTHORIZATION Authorization)
  # gets BASIC auth info
  def get_auth_data
    auth_key  = @@http_auth_headers.detect { |h| request.env.has_key?(h) }
    auth_data = request.env[auth_key].to_s.split unless auth_key.blank?
    auth_data && auth_data[0] == 'Basic' ? Base64.decode64(auth_data[1]).split(':')[0..1] : [nil, nil]
  end
end
