class AccountController < ApplicationController
  # see user model for info about activation code
  # for email password reminders and activation
  # depreciated in rails 2.0
  # now in config/environment.rb (later to go into config/initializers/)
  # observer :user_observer

  include ExtendedContent
  include ExtendedContentController
  include EmailController

  # Be sure to include AuthenticationSystem in Application Controller instead
  # include AuthenticatedSystem
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie

  before_filter :redirect_if_user_portraits_arnt_enabled, :only => [:add_portrait, :remove_portrait, :make_selected_portrait]

  # say something nice, you goof!  something sweet.
  def index
    if logged_in? || User.count > 0
      redirect_to_default_all
    else
      redirect_to(:action => 'signup')
    end
  end

  def login
    if request.post?
      self.current_user = User.authenticate(params[:login], params[:password])
      if logged_in?
        if params[:remember_me] == "1"
          self.current_user.remember_me
          cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
        end
        move_session_searches_to_current_user
        flash[:notice] = t('account_controller.login.logged_in')
        redirect_back_or_default({ :locale => current_user.locale,
                                   :urlified_name => @site_basket.urlified_name,
                                   :controller => 'account',
                                   :action => 'index' }, current_user.locale)
      else
        flash[:notice] = t('account_controller.login.failed_login')
      end
    else
      logger.debug("what is return_to: " + session[:return_to].inspect)
      if !session[:return_to].blank? && session[:return_to].include?('find_related')
        render :layout => "simple"
      end
    end
  end

  # override brain_buster method to suit our UI
  # and working in conjunction with simple_captcha
  def captcha_failure
    @user.security_code = 'failed'
    @user.security_code_confirmation = false
  end


  def signup
    # this loads @content_type
    load_content_type

    @user = User.new

    # Walter McGinnis, 2008-03-16
    # making it so that system setting
    # determines which type of captcha method we use
    @captcha_type = params[:captcha_type] || CAPTCHA_TYPE
    @captcha_type = 'image' if @captcha_type == 'all'

    create_brain_buster if @captcha_type == 'question'

    # after this is processing submitted form only
    return unless request.post?
    @user = User.new(params[:user].reject { |k, v| k == "captcha_type" })

    case @captcha_type
    when 'image'
      if simple_captcha_valid?
        @user.security_code = params[:user][:security_code]
      end

      if simple_captcha_confirm_valid?
        @res = Captcha.find(session[:captcha_id])
        @user.security_code_confirmation = @res.text
      else
        @user.security_code_confirmation = false
      end
    when 'question'
      if validate_brain_buster
        @user.security_code = true
        @user.security_code_confirmation = true
      end
    end

    if agreed_terms?
      @user.agree_to_terms = params[:user][:agree_to_terms]
    end

    @user.save!

    @user.add_as_member_to_default_baskets

    if !REQUIRE_ACTIVATION
      self.current_user = @user
      move_session_searches_to_current_user
      flash[:notice] = t('account_controller.signup.signed_up')
    else
      flash[:notice] = t('account_controller.signup.signed_up_with_email')
    end

    redirect_back_or_default({ :locale => params[:user][:locale],
                               :urlified_name => @site_basket.urlified_name,
                               :controller => 'account',
                               :action => 'index' })
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end

  def fetch_gravatar
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace_html params[:avatar_id],
                            avatar_tag(User.new({ :email => params[:email] || String.new }),
                                                { :size => 30, :rating => 'G', :gravatar_default_url => "#{SITE_URL}images/no-avatar.png" },
                                                { :width => 30, :height => 30, :alt => t('account_controller.fetch_gravatar.your_gravatar') })
        end
      end
    end
  end

  def simple_captcha_valid?
    if params[:user][:security_code] != ''
      return true
    end
  end

  def agreed_terms?
    if params[:user][:agree_to_terms] == '1'
      return true
    end
  end

  def simple_captcha_confirm_valid?
    if params[:user][:security_code]
      @res = Captcha.find(session[:captcha_id])
      if @res.text == params[:user][:security_code]
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    # Walter McGinnis, 2008-03-16
    # added to support brain_buster plugin captcha
    cookies.delete :captcha_status
    reset_session
    flash[:notice] = t('account_controller.logout.logged_out')
    redirect_back_or_default(:controller => '/account', :action => 'index')
  end

  def show
    if logged_in?
      if params[:id]
        @user = User.find(params[:id])
      else
        @user = self.current_user
      end
      @viewer_is_user = (@user == @current_user) ? true : false
      @viewer_portraits = !@user.portraits.empty? ? @user.portraits.all(:conditions => ['position != 1']) : nil
    else
      flash[:notice] = t('account_controller.show.please_login')
      redirect_to :action => 'login'
    end
  end

  def edit
    @user = User.find(self.current_user.id)
  end

  def update
    @user = User.find(self.current_user.id)

    original_user_name = @user.user_name
    if @user.update_attributes(params[:user])
      # @user.user_name has changed
      expire_contributions_caches_for(@user) if original_user_name != @user.user_name

      flash[:notice] = t('account_controller.update.user_updated')
      redirect_to({ :locale => params[:user][:locale],
                    :urlified_name => @site_basket.urlified_name,
                    :controller => 'account',
                    :action => 'show',
                    :id => @user })
    else
      logger.debug("what is problem")
      render :action => 'edit'
    end
  end

  def change_password
    return unless request.post?
    if User.authenticate(current_user.login, params[:old_password])
      if (params[:password] == params[:password_confirmation])
        current_user.password_confirmation = params[:password_confirmation]
        current_user.password = params[:password]
        flash[:notice] = current_user.save ?
        t('account_controller.change_password.password_changed') :
          t('account_controller.change_password.password_not_changed')
        if IS_CONFIGURED
          redirect_to :action => 'show'
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

  def show_captcha
    return unless !params[:id].nil?
    captcha = Captcha.find(params[:id])
    imgdata = captcha.imageblob
    send_data(imgdata,
              :filename => 'captcha.jpg',
              :type => 'image/jpeg',
              :disposition => 'inline')
  end

  def disclaimer
    @topic = Topic.find(params[:id])
    respond_to do |format|
      format.html { render :partial => 'account/disclaimer', :layout => 'simple' }
      format.js
    end
  end

  # activation code, note, not always used
  # if REQUIRE_ACTIVATION is false, this isn't used
  def activate
    flash.clear
    return if params[:id].nil? and params[:activation_code].nil?
    activator = params[:id] || params[:activation_code]
    @user = User.find_by_activation_code(activator)
    if @user and @user.activate
      flash[:notice] = t('account_controller.activate.activated')
      redirect_back_or_default(:controller => '/account', :action => 'login')
    else
      flash[:error] = t('account_controller.activate.not_activated')
    end
  end

  # supporting password reset
  def forgot_password
    return unless request.post?
    @users = !params[:user][:login].blank? ? User.find_all_by_email_and_login(params[:user][:email], params[:user][:login]) :
                                             User.find_all_by_email(params[:user][:email])
    if @users.size == 1
      user = @users.first
      user.forgot_password
      user.save
      redirect_back_or_default(:controller => '/account', :action => 'index')
      flash[:notice] = t('account_controller.forgot_password.email_sent')
    elsif @users.size > 1
      flash[:notice] = t('account_controller.forgot_password.more_than_one_account')
    elsif !params[:user][:login].blank?
      flash[:error] = t('account_controller.forgot_password.no_such_login')
    else
      flash[:error] = t('account_controller.forgot_password.no_such_email')
    end
  end

  def reset_password
    @user = User.find_by_password_reset_code(params[:id]) if params[:id]
    raise if @user.nil?
    # form should have user hash after it's been submitted
    return if @user unless params[:user]
    if (params[:user][:password] == params[:user][:password_confirmation])
      self.current_user = @user #for the next two lines to work
      current_user.password_confirmation = params[:user][:password_confirmation]
      current_user.password = params[:user][:password]
      @user.reset_password
      flash[:notice] = current_user.save ? t('account_controller.reset_password.password_reset') : t('account_controller.reset_password.password_not_reset')
    else
      flash[:notice] = t('account_controller.reset_password.password_mismatch')
    end
    redirect_back_or_default(:controller => '/account', :action => 'index')
  rescue
    logger.error "Invalid Reset Code entered"
    flash[:notice] = t('account_controller.reset_password.invalid_reset')
    redirect_back_or_default(:controller => '/account', :action => 'index')
  end

  def add_portrait
    @still_image = StillImage.find(params[:id])
    if UserPortraitRelation.new_portrait_for(current_user, @still_image)
      flash[:notice] = t('account_controller.add_portrait.added_portrait', :portrait_title => @still_image.title)
    else
      flash[:error] = t('account_controller.add_portrait.failed_portrait', :portrait_title => @still_image.title)
    end
    expire_contributions_caches_for(current_user, :dont_rebuild_zoom => true)
    redirect_to_image_or_profile
  end

  def remove_portrait
    @still_image = StillImage.find(params[:id])
    if UserPortraitRelation.remove_portrait_for(current_user, @still_image)
      @successful = true
      flash[:notice] = t('account_controller.remove_portrait.removed_portrait', :portrait_title => @still_image.title)
    else
      @successful = false
      flash[:error] = t('account_controller.remove_portrait.failed_portrait', :portrait_title => @still_image.title)
    end
    expire_contributions_caches_for(current_user, :dont_rebuild_zoom => true)
    respond_to do |format|
      format.html { redirect_to_image_or_profile }
      format.js { render :file => File.join(RAILS_ROOT, 'app/views/account/portrait_controls.js.rjs') }
    end
  end

  def make_selected_portrait
    @still_image = StillImage.find(params[:id])
    if UserPortraitRelation.make_portrait_selected_for(current_user, @still_image)
      flash[:notice] = t('account_controller.make_selected_portrait.made_selected', :portrait_title => @still_image.title)
    else
      flash[:error] = t('account_controller.make_selected_portrait.failed_portrait', :portrait_title => @still_image.title)
    end
    expire_contributions_caches_for(current_user, :dont_rebuild_zoom => true)
    redirect_to_image_or_profile
  end

  def move_portrait_higher
    @still_image = StillImage.find(params[:id])
    if UserPortraitRelation.move_portrait_higher_for(current_user, @still_image)
      @successful = true
      flash[:notice] = t('account_controller.move_portrait_higher.moved_higher', :portrait_title => @still_image.title)
    else
      @successful = false
      flash[:error] = t('account_controller.move_portrait_higher.failed_portrait', :portrait_title => @still_image.title)
    end
    expire_contributions_caches_for(current_user, :dont_rebuild_zoom => true)
    respond_to do |format|
      format.html { redirect_to_image_or_profile }
      format.js { render :file => File.join(RAILS_ROOT, 'app/views/account/portrait_controls.js.rjs') }
    end
  end

  def move_portrait_lower
    @still_image = StillImage.find(params[:id])
    if UserPortraitRelation.move_portrait_lower_for(current_user, @still_image)
      @successful = true
      flash[:notice] = t('account_controller.move_portrait_lower.moved_lower', :portrait_title => @still_image.title)
    else
      @successful = false
      flash[:error] = t('account_controller.move_portrait_lower.failed_portrait', :portrait_title => @still_image.title)
    end
    expire_contributions_caches_for(current_user, :dont_rebuild_zoom => true)
    respond_to do |format|
      format.html { redirect_to_image_or_profile }
      format.js { render :file => File.join(RAILS_ROOT, 'app/views/account/portrait_controls.js.rjs') }
    end
  end

  def update_portraits
    begin
      portrait_ids = params[:portraits].gsub('&', '').split('portrait_images[]=')
      # portrait_ids will now contain two blank spaces at the front, then the order of other portraits
      # we could strip these, but they actually work well here. One of then aligns positions with array indexs
      # The other fills in for the selected portrait not in this list.
      logger.debug("Portrait Order: #{portrait_ids.inspect}")
      # Move everything to position one (so that the one that isn't updated remains the selected)
      UserPortraitRelation.update_all({ :position => 1 }, { :user_id => current_user })
      # Get all of the portrait relations in one query
      portrait_list = current_user.user_portrait_relations
      # For each of the portrait ids, update their position based on the array index
      portrait_ids.each_with_index do |portrait_id,index|
        # The first element we leave in (to represent the selected portrait)
        next if portrait_id.blank?
        # Get this portrait from the portrait_list array
        portrait_placement = portrait_list.select { |placement| placement.still_image_id.to_i == portrait_id.to_i }.first
        # once we have the portrait, update the position to index
        portrait_placement.update_attribute(:position, index)
      end
      expire_contributions_caches_for(current_user, :dont_rebuild_zoom => true)
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

  def baskets
  end

  def change_locale
    notice = t('account_controller.change_locale.locale_changed')
    notice += t('account_controller.change_locale.change_permanently') if logged_in?
    flash[:notice] = notice
    redirect_back_or_default({:controller => 'account', :action => 'index'}, params[:override_locale])
  end

  private

    def redirect_if_user_portraits_arnt_enabled
      unless ENABLE_USER_PORTRAITS
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

    def ssl_required?
      FORCE_HTTPS_ON_RESTRICTED_PAGES || false
    end

    # If ssl_allowed? returns true, the SSL requirement is not enforced,
    # so ensure it is not set in this controller.
    def ssl_allowed?
      nil
    end

end
