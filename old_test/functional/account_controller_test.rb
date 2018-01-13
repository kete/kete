require File.dirname(__FILE__) + '/../test_helper'

# Require stubs
require File.dirname(__FILE__) + '/../stubs/captcha'

set_constant('SystemSetting.enable_user_portraits?', true)

class AccountControllerTest < ActionController::TestCase

  include KeteTestFunctionalHelper

  # fixtures preloaded
  fixtures :users

  def setup
    @base_class = "Account"

    # for testing action mailer
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []
    @emails = ActionMailer::Base.deliveries
    @emails.clear

    @admin = User.find_by_login('admin')

    # kete specific
    @urlified_name = Basket.find(:first).urlified_name
  end

  def test_should_login_and_redirect
    post :login, :urlified_name => @urlified_name, :login => 'admin', :password => 'test', :urlified_name => @urlified_name
    assert session[:user]
    assert_response :redirect
  end

  def test_should_fail_login_and_not_redirect
    post :login, :urlified_name => @urlified_name, :login => 'admin', :password => 'bad password', :urlified_name => @urlified_name
    assert_nil session[:user]
    assert_response :success
  end

  def test_should_allow_signup
    assert_difference('User.count') do
      create_user
      assert_response :redirect
      assert_equal 'Thanks for signing up!', flash[:notice]
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference('User.count') do
      create_user(:login => nil)
      assert assigns(:user).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference('User.count') do
      create_user(:password => nil)
      assert assigns(:user).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference('User.count') do
      create_user(:password_confirmation => nil)
      assert assigns(:user).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference('User.count') do
      create_user(:email => nil)
      assert assigns(:user).errors.on(:email)
      assert_response :success
    end
  end

  def test_should_logout
    login_as :admin
    get :logout, :urlified_name => @urlified_name
    assert_nil session[:user]
    assert_response :redirect
  end

  def test_should_remember_me
    post :login, :urlified_name => @urlified_name, :login => 'admin', :password => 'test', :remember_me => "1", :urlified_name => @urlified_name
    assert_not_nil @response.cookies["auth_token"]
  end

  def test_should_not_remember_me
    post :login, :urlified_name => @urlified_name, :login => 'admin', :password => 'test', :remember_me => "0", :urlified_name => @urlified_name
    assert_nil @response.cookies["auth_token"]
  end

  def test_should_delete_token_on_logout
    login_as :admin
    get :logout, :urlified_name => @urlified_name
    assert_nil @response.cookies["auth_token"]
  end

  def test_should_login_with_cookie
    @admin.remember_me
    @request.cookies["auth_token"] = cookie_for(:admin)
    get :index, :urlified_name => @urlified_name
    assert @controller.send(:logged_in?)
  end

  def test_should_fail_expired_cookie_login
    @admin.remember_me
    @admin.update_attribute :remember_token_expires_at, 5.minutes.ago
    @request.cookies["auth_token"] = cookie_for(:admin)
    get :index, :urlified_name => @urlified_name
    assert !@controller.send(:logged_in?)
  end

  def test_should_fail_cookie_login
    @admin.remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :index, :urlified_name => @urlified_name
    assert !@controller.send(:logged_in?)
  end

  ### mailer tests
  def test_should_activate_user_and_send_activation_email
    get :activate, :id => User.find_by_login('arthur').activation_code, :urlified_name => @urlified_name
    assert_equal 1, @emails.length
    assert(@emails.first.subject =~ /Your account has been activated/)
    assert(@emails.first.body    =~ /#{ assigns(:user).login}, your account has been activated/)
  end

  def test_should_send_activation_email_after_signup
    # Override constant to test for activation email
    set_constant('REQUIRE_ACTIVATION', true)

    create_user
    assert_equal 1, @emails.length
    assert_match /Please activate your new account/, @emails.first.subject
    assert_match /User name: quire/, @emails.first.body
    assert_match /Password: quire/, @emails.first.body
    assert_match /account\/activate\/#{assigns(:user).activation_code}/, @emails.first.body
  end

  ### password resetting tests
  def test_should_forget_password
    post :forgot_password, :urlified_name => @urlified_name, :user => { :email => 'admin@changeme.com' }
    assert_response :redirect
    assert_equal "A password reset link has been sent to your email address", flash[:notice]
    assert_equal 1, @emails.length
    assert(@emails.first.subject =~ /Request to change your password/)
  end

  def test_should_not_forget_password
    post :forgot_password, :urlified_name => @urlified_name, :user => { :email => 'invalid@email' }
    assert_response :success
    assert_equal "Could not find a user with that email address", flash[:error]
    assert_equal 0, @emails.length
  end

  def test__reset_password__valid_code_and_password__should_reset
    @user = User.find(1)
    @user.forgot_password && @user.save
    assert_equal 1, @emails.length # make sure that it e-mails the user notifying that their password was reset

    post :reset_password, :id => @user.password_reset_code, :user => { :password => "new_password", :password_confirmation => "new_password" }, :urlified_name => @urlified_name

    assert_match("Password reset", flash[:notice])
    assert_equal 2, @emails.length # make sure that it e-mails the user notifying that their password was reset
    assert_equal(@user.email, @emails.first.to[0], "should have gone to user")
    #
    # # Make sure that the user can login with this new password
    assert(User.authenticate(@user.login, "new_password"), "password should have been reset")
  end

  def test__reset_password__valid_code_but_not_matching_password__shouldnt_reset
    @user = User.find(1)
    @user.forgot_password && @user.save
    assert_equal(1, @emails.length) # Forgot password email dispatched

    post :reset_password, :id => @user.password_reset_code, :user => { :password => "new_password", :password_confirmation => "not matching password" }, :urlified_name => @urlified_name

    assert_equal(1, @emails.length) # No further email dispatched due to password mismatch.
    assert_match("Password mismatch", flash[:notice])

    assert(!User.authenticate(@user.login, "new_password"), "password should not have been reset")
  end

  def test__reset_password__invalid_code__should_show_error
    post :reset_password, :id => "Invalid Code", :password => "new_password", :password_confirmation => "not matching password", :urlified_name => @urlified_name

    assert_match(/invalid password reset code/, flash[:notice])
  end

  ### changing password tests
  def test_should_allow_password_change
    post :change_password, { :old_password => 'test', :password => 'newpassword', :password_confirmation => 'newpassword', :urlified_name => @urlified_name }, {  :user => 2 }
    assert_equal 'newpassword', assigns(:current_user).password
    assert_equal "Password changed", flash[:notice]
    post :logout, :urlified_name => @urlified_name
    assert_nil session[:user]
    post :login, :login => 'bryan', :password => 'newpassword', :urlified_name => @urlified_name
    assert session[:user]
    assert_response :redirect
    assert_redirected_to :urlified_name => @urlified_name, :controller => 'account', :action => 'index', :locale => :en
  end

  def test_non_matching_passwords_should_not_change
    post :login, :login => 'bryan', :password => 'test', :urlified_name => @urlified_name
    assert session[:user]
    post :change_password, {  :old_password => 'test', :password => 'newpassword', :password_confirmation => 'test', :urlified_name => @urlified_name }
    assert_not_equal 'newpassword', assigns(:current_user).password
    assert_equal "Password mismatch", flash[:notice]
  end

  def test_incorrect_old_password_does_not_change
    post :login, :login => 'bryan', :password => 'test', :urlified_name => @urlified_name
    assert session[:user]
    post :change_password, { :old_password => 'wrongpassword', :password => 'newpassword', :password_confirmation => 'newpassword', :urlified_name => @urlified_name }
    assert_not_equal 'newpassword', assigns(:current_user).password, "#{assigns(:current_user).password} expected to be 'newpassword'"
    assert_equal "Wrong password", flash[:notice]
  end

  ### user activation tests
  def test_should_activate_user
    assert_nil User.authenticate('arthur', 'test')
    get :activate, :id => User.find_by_login('arthur').activation_code, :urlified_name => @urlified_name
    assert_equal User.find_by_login('arthur'), User.authenticate('arthur', 'test')
  end

  def test_should_not_activate_nil
    get :activate, :activation_code => nil, :urlified_name => @urlified_name
    assert_activate_error
  end

  def test_should_not_activate_bad
    get :activate, :activation_code => 'foobar', :urlified_name => @urlified_name
    assert flash.has_key?(:error), "Flash should contain error message."
    assert_activate_error
  end

  def assert_activate_error
    assert_response :success
    assert_template "account/activate"
  end

  def test_add_portrait
    login_as :admin
    still_image = StillImage.create({ :title => 'test still image', :basket_id => Basket.find(:first) })
    get :add_portrait, :urlified_name => 'site', :id => still_image.id
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site', :controller => 'images', :action => 'show', :id => assigns(:still_image), :locale => false
  end

  def test_remove_portrait
    login_as :admin
    still_image = StillImage.create({ :title => 'test still image', :basket_id => Basket.find(:first) })
    get :add_portrait, :urlified_name => 'site', :id => still_image.id
    get :remove_portrait, :urlified_name => 'site', :id => still_image.id
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site', :controller => 'images', :action => 'show', :id => assigns(:still_image), :locale => false
  end

  def test_make_selected_portrait
    login_as :admin
    still_image = StillImage.create({ :title => 'test still image', :basket_id => Basket.find(:first) })
    get :add_portrait, :urlified_name => 'site', :id => still_image.id
    get :make_selected_portrait, :urlified_name => 'site', :id => still_image.id
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site', :controller => 'images', :action => 'show', :id => assigns(:still_image), :locale => false
  end

  protected
    # James is working on this..
    def create_user(options = {})
      post :signup, { :user => { :login => 'quire', :email => 'quire@changme.com',
        :password => 'quire', :password_confirmation => 'quire', :captcha_type => 'image',
        :agree_to_terms => '1', :security_code => 'test', :locale => 'en' }.merge(options), :urlified_name => @urlified_name },
        { :captcha_id => 1 }
    end

    def auth_token(token)
      CGI::Cookie.new('name' => 'auth_token', 'value' => token)
    end

    def cookie_for(user)
      auth_token User.find_by_login(user.to_s).remember_token
    end
end
