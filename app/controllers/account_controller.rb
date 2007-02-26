require 'RMagick'
class AccountController < ApplicationController
  before_filter :load_content_type, :only => [:signup]
  
#  include GenerateCaptcha
  include ExtendedContent

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

    self.current_user = @user
    redirect_back_or_default(:controller => '/account', :action => 'index')
    flash[:notice] = "Thanks for signing up!"
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
      @user = self.current_user
    else 
      redirect_to :action => 'index'
    end
  end
  
  def edit
    @user = User.find(self.current_user.id)
  end
  
  def update
    @user = User.find(self.current_user.id)
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'index'
    else
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
					      
  
  private
  def load_content_type
    @content_type = ContentType.find_by_class_name('User')
  end
end
