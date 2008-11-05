require File.dirname(__FILE__) + '/../test_helper'
require 'baskets_controller'

# Re-raise errors caught by the controller.
class BasketsController; def rescue_action(e) raise e end; end

class BasketsControllerTest < Test::Unit::TestCase
  # fixtures are preloaded if necessary
  
  include ItemPrivacyTestHelper::TestHelper
  include AuthenticatedTestHelper
  
  def setup
    @base_class = "Basket"

    # hash of params to create new instance of model, e.g. {:name => 'Test Model', :description => 'Dummy'}
    @new_model = { :name => 'test basket', :private_default => false, :file_private_default => false }
    @req_attr_names = %w(name private_default file_private_default) 
    # name of fields that must be present, e.g. %(name description)
    @duplicate_attr_names = %w( ) # name of fields that cannot be a duplicate, e.g. %(name description)
    
    load_test_environment
    
    login_as(:admin)
  end

  def test_new
    get :new, :urlified_name => 'site'
    assert_response :success
    assert_template 'baskets/new'
  end
  
  def new_has_correct_defaults
    get :new, :urlified_name => 'site'
    assert_response :success
    assert_template 'baskets/new'
    assert_equal false, :private_default
    assert_equal false, :file_private_default
    assert_equal false, :allow_non_member_comments
  end
  
  def test_create
    post :create, :basket => @new_model, :urlified_name => 'site'
    assert_not_nil assigns(:basket)
    assert_equal false, assigns(:basket).private_default
    assert_equal false, assigns(:basket).file_private_default
    assert_equal false, assigns(:basket).new_record?
    assert_response :redirect
    assert_redirected_to :controller => 'baskets', :action => 'edit', :id => assigns(:basket).id, :urlified_name => assigns(:basket).urlified_name
  end
  
  def test_edit
    get :edit, :id => 1, :urlified_name => 'site'
    assert_response :success
    assert_template 'baskets/edit'
  end
  
  def test_update
    post :update, :id => 1, :basket => { :private_default => 'true', :file_private_default => 'true' }, :urlified_name => 'site'
    assert_not_nil assigns(:basket)
    assert_equal true, assigns(:basket).private_default
    assert_equal true, assigns(:basket).file_private_default
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site'
    assert_equal 'Basket was successfully updated.', flash[:notice]
  end

  def test_contact_restricted
    logout # logout to test contact form restricted
    # test contact form restricted to logged in members
    get :contact, :urlified_name => 'site'
    assert_response :redirect
    assert_redirected_to :controller => 'account', :action => 'login'
  end

  def test_contact
    # test redirect when disabled
    get :contact, :urlified_name => 'site'
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site'
    assert_equal "This contact form is not currently enabled.", flash[:notice]

    Basket.first.settings[:allow_basket_admin_contact] = true

    # test routes in place work
    get :contact, :urlified_name => 'site'
    assert_response :success
    assert_template 'email/contact'

    # test basic validation working
    post :send_email, :urlified_name => 'site'
    assert_response :success
    assert_template 'email/contact'
    assert_equal "Both subject and message must be filled in. Please try again.", flash[:error]

    # test successfull emailing
    post :send_email, :contact => { :subject => "test", :message => "test" }, :urlified_name => 'site'
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site'
    assert_equal "Your email has been sent. You will receive the reply in your email box.", flash[:notice]
  end

  private

  # Change a setting on a basket
  def change_setting_on_basket(basket_urlified_name, setting, value)
    @basket = Basket.find_by_urlified_name(basket_urlified_name)
    raise "#{basket_urlified_name} basket not found" if @basket.nil?
    @basket.settings[setting.to_sym] = value
  end

end
