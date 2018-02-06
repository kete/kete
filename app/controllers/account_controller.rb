class AccountController < ApplicationController
  #####################################################################
  #####################################################################
  ### CONFIGURATION
  #####################################################################
  #####################################################################
  # Be sure to include AuthenticationSystem in Application Controller instead
  # include AuthenticatedSystem
  # If you want "remember me" functionality, add this before_filter to Application Controller

  before_filter :login_from_cookie
  before_filter :redirect_if_user_portraits_arnt_enabled, only: %i[add_portrait remove_portrait make_selected_portrait]
  layout :simple_or_application

  #####################################################################
  #####################################################################
  ### PUBLIC METHODS/ACTIONS
  #####################################################################
  #####################################################################

  include ExtendedContent
  include ExtendedContentController
  include EmailController
  include SslControllerHelpers
  def index
    if logged_in? || User.count > 0
      redirect_to_default_all
    else
      redirect_to(action: 'signup')
    end
  end

  def login
    if request.post?

      # check for login/password
      # else anonymous user
      # and check captcha
      # store name, email, website in session
      if params[:login].present? && params[:password].present?
        self.current_user = User.authenticate(params[:login], params[:password])
      else
        if anonymous_ok_for?(session[:return_to]) &&
           @security_code == @security_code_confirmation &&
           params[:email].present? && params[:email] =~ /^[^@\s]+@[^@\s]+$/i

          @anonymous_user = User.find_by_login('anonymous')

          anonymous_name = params[:name].blank? ? @anonymous_user.user_name : params[:name]

          session[:anonymous_user] = { 
            name: anonymous_name,
            email: params[:email] 
          }

          # see if the submitted website is valid
          # append protocol if they have left it off
          website = params[:website]
          website = 'http://' + website unless website.include?('http')

          temp_weblink = WebLink.new(title: 'placeholder', url: website)

          session[:anonymous_user][:website] = website if temp_weblink.valid?

          self.current_user = @anonymous_user
        end
      end

      if logged_in?
        # anonymous users can't use remember me, check for login password
        if @anonymous_user.blank? && params[:remember_me] == '1'
          current_user.remember_me
          cookies[:auth_token] = { value: current_user.remember_token, expires: current_user.remember_token_expires_at }
        end
        unless @anonymous_user
          move_session_searches_to_current_user
          flash[:notice] = t('account_controller.login.logged_in')
        end
        redirect_back_or_default(
          { 
            locale: current_user.locale,
            urlified_name: @site_basket.urlified_name,
            controller: 'account',
            action: 'index' 
          }, current_user.locale
        )
      else
        if params[:login].present? && params[:password].present?
          flash[:notice] = t('account_controller.login.failed_login')
        else
          error_msgs = Array.new

          if params[:email].blank? || !params[:email].include?('@')
            error_msgs << t('account_controller.login.invalid_email')
          end

          if @security_code != @security_code_confirmation || @security_code.blank?
            error_msgs << t('account_controller.login.failed_security_answer')
          end

          flash[:notice] = error_msgs.join(t('account_controller.login.or').to_s)
        end
      end
    end
  end

  def signup
    # this loads @content_type
    load_content_type

    @user = User.new

    # after this is processing submitted form only
    return unless request.post?
    # @user = User.new(params[:user].reject { |k, v| k == "captcha_type" })
    @user = User.new(params[:user])

    if agreed_terms?
      @user.agree_to_terms = params[:user][:agree_to_terms]
    end

    # We have removed captcha and will re-enable something if/when dummy
    # sign-ups becomes a problem.
    @user.security_code = true
    @user.security_code_confirmation = true

    @user.save!

    @user.add_as_member_to_default_baskets

    if !SystemSetting.require_activation?
      self.current_user = @user
      move_session_searches_to_current_user
      flash[:notice] = t('account_controller.signup.signed_up')
    else
      if SystemSetting.administrator_activates?
        flash[:notice] = t('account_controller.signup.signed_up_admin_will_review')
      else
        flash[:notice] = t('account_controller.signup.signed_up_with_email')
      end
    end

    redirect_back_or_default({ 
                               locale: params[:user][:locale],
                               urlified_name: @site_basket.urlified_name,
                               controller: 'account',
                               action: 'index' 
                             })
  rescue ActiveRecord::RecordInvalid
    render action: 'signup'
  end

  def disclaimer
    @topic = Topic.find(params[:id])
    respond_to do |format|
      format.html { render partial: 'account/disclaimer', layout: 'simple' }
      format.js
    end
  end

  def forgot_password
    return unless request.post?
    @users =
      !params[:user][:login].blank? ? User.find_all_by_email_and_login(params[:user][:email], params[:user][:login]) :
                                                  User.find_all_by_email(params[:user][:email])
    if @users.size == 1
      user = @users.first
      user.forgot_password
      user.save
      redirect_back_or_default(controller: '/account', action: 'index')
      flash[:notice] = t('account_controller.forgot_password.email_sent')
    elsif @users.size > 1
      flash[:notice] = t('account_controller.forgot_password.more_than_one_account')
    elsif !params[:user][:login].blank?
      flash[:error] = t('account_controller.forgot_password.no_such_login')
    else
      flash[:error] = t('account_controller.forgot_password.no_such_email')
    end
  end
  #####################################################################
  #####################################################################
  ### not sure of visiblity yet
  #####################################################################


  def simple_return_tos
    ['find_related']
  end

  def fetch_gravatar
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace_html params[:avatar_id],
                            avatar_tag(
                              User.new({ email: params[:email] || String.new }),
                              { size: 30, rating: 'G', gravatar_default_url: '/images/no-avatar.png' },
                              { width: 30, height: 30, alt: t('account_controller.fetch_gravatar.your_gravatar') }
                            )
        end
      end
    end
  end

  def agreed_terms?
    return true if params[:user][:agree_to_terms] == '1'
  end

  def logout
    deauthenticate
    flash[:notice] = t('account_controller.logout.logged_out')
    redirect_back_or_default(
      controller: 'index_page',
      urlified_name: @current_basket.urlified_name,
      action: 'index'
    )
  end

  def show
    if logged_in?
      if params[:id]
        @user = User.find(params[:id])
      else
        @user = current_user
      end
      @viewer_is_user = @user == @current_user
      @viewer_portraits = !@user.portraits.empty? ? @user.portraits.all(conditions: ['position != 1']) : nil
    else
      flash[:notice] = t('account_controller.show.please_login')
      redirect_to action: 'login'
    end
  end

  def edit
    @user = User.find(current_user.id)
  end

  def update
    @user = User.find(current_user.id)

    original_user_name = @user.user_name
    if @user.update_attributes(params[:user])

      flash[:notice] = t('account_controller.update.user_updated')
      redirect_to({ 
                    locale: params[:user][:locale],
                    urlified_name: @site_basket.urlified_name,
                    controller: 'account',
                    action: 'show',
                    id: @user 
                  })
    else
      logger.debug('what is problem')
      render action: 'edit'
    end
  end

  def change_password
    return unless request.post?
    if User.authenticate(current_user.login, params[:old_password])
      if params[:password] == params[:password_confirmation]
        current_user.password_confirmation = params[:password_confirmation]
        current_user.password = params[:password]
        flash[:notice] =
          current_user.save ?
                 t('account_controller.change_password.password_changed') :
                   t('account_controller.change_password.password_not_changed')
        if SystemSetting.is_configured?
          redirect_to action: 'show'
        else
          redirect_to '/'
        end
      else
        flash[:notice] = t('account_controller.change_password.password_mismatch')
        @old_password = params[:old_password]
      end
    else
      flash[:notice] = t('account_controller.change_password.wrong_password')
    end
  end

  # activation code, note, not always used
  # if REQUIRE_ACTIVATION is false, this isn't used
  def activate
    flash.clear
    return if params[:id].nil? && params[:activation_code].nil?
    activator = params[:id] || params[:activation_code]
    @user = User.find_by_activation_code(activator)
    if @user && @user.activate
      if SystemSetting.administrator_activates?
        flash[:notice] = t('account_controller.activate.admin_activated', new_user: @user.resolved_name)
        redirect_back_or_default(
          controller: '/account',
          action: 'show',
          id: @user.id
        )
      else
        flash[:notice] = t('account_controller.activate.activated')
        redirect_back_or_default(controller: '/account', action: 'login')
      end
    else
      flash[:error] = t('account_controller.activate.not_activated')
    end
  end

  def reset_password
    @user = User.find_by_password_reset_code(params[:id]) if params[:id]
    raise if @user.nil?
    # form should have user hash after it's been submitted
    return if @user unless params[:user]
    if params[:user][:password] == params[:user][:password_confirmation]
      self.current_user = @user # for the next two lines to work
      current_user.password_confirmation = params[:user][:password_confirmation]
      current_user.password = params[:user][:password]
      @user.reset_password
      flash[:notice] = current_user.save ? t('account_controller.reset_password.password_reset') : t('account_controller.reset_password.password_not_reset')
    else
      flash[:notice] = t('account_controller.reset_password.password_mismatch')
    end
    redirect_back_or_default(controller: '/account', action: 'index')
  rescue
    logger.error 'Invalid Reset Code entered'
    flash[:notice] = t('account_controller.reset_password.invalid_reset')
    redirect_back_or_default(controller: '/account', action: 'index')
  end

  def add_portrait
    @still_image = StillImage.find(params[:id])
    if UserPortraitRelation.new_portrait_for(current_user, @still_image)
      flash[:notice] = t('account_controller.add_portrait.added_portrait', portrait_title: @still_image.title)
    else
      flash[:error] = t('account_controller.add_portrait.failed_portrait', portrait_title: @still_image.title)
    end
    redirect_to_image_or_profile
  end

  def remove_portrait
    @still_image = StillImage.find(params[:id])
    if UserPortraitRelation.remove_portrait_for(current_user, @still_image)
      @successful = true
      flash[:notice] = t('account_controller.remove_portrait.removed_portrait', portrait_title: @still_image.title)
    else
      @successful = false
      flash[:error] = t('account_controller.remove_portrait.failed_portrait', portrait_title: @still_image.title)
    end
    respond_to do |format|
      format.html { redirect_to_image_or_profile }
      format.js { render file: File.join(Rails.root, 'app/views/account/portrait_controls.js.rjs') }
    end
  end

  def make_selected_portrait
    @still_image = StillImage.find(params[:id])
    if UserPortraitRelation.make_portrait_selected_for(current_user, @still_image)
      flash[:notice] = t('account_controller.make_selected_portrait.made_selected', portrait_title: @still_image.title)
    else
      flash[:error] = t('account_controller.make_selected_portrait.failed_portrait', portrait_title: @still_image.title)
    end
    redirect_to_image_or_profile
  end

  def move_portrait_higher
    @still_image = StillImage.find(params[:id])
    if UserPortraitRelation.move_portrait_higher_for(current_user, @still_image)
      @successful = true
      flash[:notice] = t('account_controller.move_portrait_higher.moved_higher', portrait_title: @still_image.title)
    else
      @successful = false
      flash[:error] = t('account_controller.move_portrait_higher.failed_portrait', portrait_title: @still_image.title)
    end
    respond_to do |format|
      format.html { redirect_to_image_or_profile }
      format.js { render file: File.join(Rails.root, 'app/views/account/portrait_controls.js.rjs') }
    end
  end

  def move_portrait_lower
    @still_image = StillImage.find(params[:id])
    if UserPortraitRelation.move_portrait_lower_for(current_user, @still_image)
      @successful = true
      flash[:notice] = t('account_controller.move_portrait_lower.moved_lower', portrait_title: @still_image.title)
    else
      @successful = false
      flash[:error] = t('account_controller.move_portrait_lower.failed_portrait', portrait_title: @still_image.title)
    end
    respond_to do |format|
      format.html { redirect_to_image_or_profile }
      format.js { render file: File.join(Rails.root, 'app/views/account/portrait_controls.js.rjs') }
    end
  end

  def update_portraits
    begin
      portrait_ids = params[:portraits].delete('&').split('portrait_images[]=')
      # portrait_ids will now contain two blank spaces at the front, then the order of other portraits
      # we could strip these, but they actually work well here. One of then aligns positions with array indexs
      # The other fills in for the selected portrait not in this list.
      logger.debug("Portrait Order: #{portrait_ids.inspect}")
      # Move everything to position one (so that the one that isn't updated remains the selected)
      UserPortraitRelation.update_all({ position: 1 }, { user_id: current_user })
      # Get all of the portrait relations in one query
      portrait_list = current_user.user_portrait_relations
      # For each of the portrait ids, update their position based on the array index
      portrait_ids.each_with_index do |portrait_id, index|
        # The first element we leave in (to represent the selected portrait)
        next if portrait_id.blank?
        # Get this portrait from the portrait_list array
        portrait_placement = portrait_list.select { |placement| placement.still_image_id.to_i == portrait_id.to_i }.first
        # once we have the portrait, update the position to index
        portrait_placement.update_attribute(:position, index)
      end
      @successful = true
      flash[:notice] = t('account_controller.update_portraits.reordered')
    rescue
      @successful = false
      flash[:error] = t('account_controller.update_portraits.not_reordered')
    end
    # This action is only called via Ajax JS request, so don't respond to HTML
    respond_to do |format|
      format.js
    end
  end

  def baskets; end

  def change_locale
    notice = t('account_controller.change_locale.locale_changed')
    notice += t('account_controller.change_locale.change_permanently') if logged_in?
    flash[:notice] = notice
    redirect_back_or_default({ controller: 'account', action: 'index' }, params[:override_locale])
  end

  #####################################################################
  #####################################################################
  ### PRIVATE METHODS
  #####################################################################
  #####################################################################

  private

  def simple_or_application
    return 'application' if session[:return_to].blank?

    simple_return_tos_regexp = Regexp.new(simple_return_tos.join('|'))

    if session[:return_to] =~ simple_return_tos_regexp ||
       (params[:as_service].present? && params[:as_service] == 'true')
      'simple'
    else
      'application'
    end
  end

  def redirect_if_user_portraits_arnt_enabled
    unless SystemSetting.enable_user_portraits?
      flash[:notice] = t('account_controller.redirect_if_user_portraits_arnt_enabled.not_enabled')
      @still_image = StillImage.find(params[:id])
      redirect_to_show_for(@still_image)
    end
  end

  def redirect_to_image_or_profile
    if session[:return_to].blank?
      redirect_to_show_for(@still_image)
    else
      redirect_to url_for(session[:return_to])
    end
  end

  def load_content_type
    @content_type = ContentType.find_by_class_name('User')
  end

end
