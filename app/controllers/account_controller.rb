require 'RMagick'
class AccountController < ApplicationController
  # see user model for info about activation code
  # for email password reminders and activation
  observer :user_observer

  include ExtendedContent
  include ExtendedContentController

  # Be sure to include AuthenticationSystem in Application Controller instead
  # include AuthenticatedSystem
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie

  # say something nice, you goof!  something sweet.
  def index
    if logged_in? || User.count > 0
      redirect_to(:urlified_name => 'site', :controller => 'search', :action => 'index')
    else
      redirect_to(:action => 'signup')
    end

    # redirect_to(:action => 'signup') unless logged_in? || User.count > 0
  end

  def login
    return unless request.post?
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(:controller => '/account', :action => 'index')
      flash[:notice] = "Logged in successfully"
    end
  end

  def signup
    # this loads @content_type
    load_content_type

    @user = User.new
    return unless request.post?
    @user = User.new(extended_fields_and_params_hash_prepare(:content_type => @content_type,
                                                             :item_key => 'user',
                                                             :item_class => 'User',
                                                             :extra_fields => ['password', 'password_confirmation']))


    if simple_captcha_valid?
      @user.security_code = params[:user][:security_code]
    end

    if simple_captcha_confirm_valid?
      @res = Captcha.find(session[:captcha_id])
      @user.security_code_confirmation = @res.text
    else
      @user.security_code_confirmation = false
    end

    if agreed_terms?
      @user.agree_to_terms = params[:user][:agree_to_terms]
    end

    logger.debug(params.to_s)

    @user.save!

    if !REQUIRE_ACTIVATION
      self.current_user = @user
      flash[:notice] = "Thanks for signing up!"
    else
      flash[:notice] = "Thanks for signing up! Expect an email with a code shortly to activate your account."
    end

    redirect_back_or_default(:controller => '/account', :action => 'index')
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
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
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => '/account', :action => 'index')
  end

  def show
    if logged_in?
      if params[:id]
        @user = User.find(params[:id])
      else
        @user = self.current_user
      end
      @extended_fields = @user.xml_attributes
    else
      flash[:notice] = "You must be logged in to view user profiles."
      redirect_to :action => 'index'
    end
  end

  def edit
    @user = User.find(self.current_user.id)
  end

  def update
    @user = User.find(self.current_user.id)

    original_user_name = @user.user_name
    if @user.update_attributes(extended_fields_and_params_hash_prepare(:content_type => @content_type,
                                                                       :item_key => 'user',
                                                                       :item_class => 'User'))
      # @user.user_name has changed
      if original_user_name != @user.user_name
        # we want to flush contribution caches
        # incase they updated something we display
        # we also want to update zoom for all items they have contributed to
        @user.distinct_contributions.each do |contribution|
          expire_contributions_caches_for(contribution)
          prepare_and_save_to_zoom(contribution)
        end
      end

      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'show', :id => @user
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
        "Password changed" :
          "Password not changed"
        redirect_to :action => 'show'
      else
        flash[:notice] = "Password mismatch"
        @old_password = params[:old_password]
      end
    else
      flash[:notice] = "Wrong password"
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
    version = params[:version]
    render(:file => "#{RAILS_ROOT}/public/about/#{version}.inc", :layout => false)
  end

  # activation code, note, not always used
  # if REQUIRE_ACTIVATION is false, this isn't used
  def activate
    flash.clear
    return if params[:id].nil? and params[:activation_code].nil?
    activator = params[:id] || params[:activation_code]
    @user = User.find_by_activation_code(activator)
    if @user and @user.activate
      flash[:notice] = "Your account has been activated.  Please login."
      redirect_back_or_default(:controller => '/account', :action => 'login')
    else
      flash[:notice] = "Unable to activate the account.  Please check or enter manually."
    end
  end

  # supporting password reset
  def forgot_password
    return unless request.post?
    if @user = User.find_by_email(params[:user][:email])
      @user.forgot_password
      @user.save
      redirect_back_or_default(:controller => '/account', :action => 'index')
      flash[:notice] = "A password reset link has been sent to your email address"
    else
      flash[:notice] = "Could not find a user with that email address"
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
      flash[:notice] = current_user.save ? "Password reset" : "Password not reset"
    else
      flash[:notice] = "Password mismatch"
    end
    redirect_back_or_default(:controller => '/account', :action => 'index')
  rescue
    logger.error "Invalid Reset Code entered"
    flash[:notice] = "Sorry - That is an invalid password reset code. Please check your code and try again. (Perhaps your email client inserted a carriage return?"
    redirect_back_or_default(:controller => '/account', :action => 'index')
  end

  private
  def load_content_type
    @content_type = ContentType.find_by_class_name('User')
  end
end
