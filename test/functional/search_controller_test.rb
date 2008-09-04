require File.dirname(__FILE__) + '/../test_helper'
require 'search_controller'

# Re-raise errors caught by the controller.
class SearchController; def rescue_action(e) raise e end; end

class SearchControllerTest < Test::Unit::TestCase
  # preloaded fixtures
  
  include AuthenticatedTestHelper
  
  def setup
    @controller = SearchController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_public_search_on_site_basket_works
    get :all, :urlified_name => 'site', :controller_name_for_zoom_class => 'topics'
    
    assert_equal false, @controller.send(:is_a_private_search?)
    assert_equal "public", @controller.send(:zoom_database)
    
    assert_response :success
    assert_nil assigns(:privacy)
    assert_equal ZoomDb.find_by_host_and_database_name('localhost', 'public'), assigns(:search).zoom_db
    assert_not_nil assigns(:results)
    
    assert_template 'search/all'
  end
  
  def test_public_search_on_about_basket_works
    get :all, :urlified_name => 'about', :controller_name_for_zoom_class => 'topics'
    
    assert_equal false, @controller.send(:is_a_private_search?)
    assert_equal "public", @controller.send(:zoom_database)
    
    assert_response :success
    assert_nil assigns(:privacy)
    assert_equal ZoomDb.find_by_host_and_database_name('localhost', 'public'), assigns(:search).zoom_db
    assert_not_nil assigns(:results)
    
    assert_template 'search/all'
  end
  
  def test_private_search_on_site_basket_is_declined_when_not_logged_in
    get :all, :urlified_name => 'site', :controller_name_for_zoom_class => 'topics', :privacy_type => 'private'
    
    assert_response :redirect
  end
  
  def test_private_search_on_about_basket_is_declined_when_not_logged_in
    get :all, :urlified_name => 'about', :controller_name_for_zoom_class => 'topics', :privacy_type => 'private'
    
    assert_response :redirect
  end
  
  def test_private_search_on_site_basket_is_allowed_when_logged_in
    login_as(:admin)
    
    get :all, :urlified_name => 'site', :controller_name_for_zoom_class => 'topics', :privacy_type => 'private'
    
    assert_response :success
    assert_template 'search/all'
    
    assert_equal true, @controller.send(:is_a_private_search?)
    assert_equal "private", @controller.send(:zoom_database)
    
    assert assigns(:privacy)
    assert_equal ZoomDb.find_by_host_and_database_name('localhost', 'private'), assigns(:search).zoom_db
    assert_not_nil assigns(:results)
  end

  def test_private_search_on_about_basket_is_allowed_when_logged_in_and_member
    login_as(:admin)
    
    get :all, :urlified_name => 'about', :controller_name_for_zoom_class => 'topics', :privacy_type => 'private'
    
    assert_equal true, @controller.send(:is_a_private_search?)
    assert_equal "private", @controller.send(:zoom_database)
    
    assert assigns(:privacy)
    assert_equal ZoomDb.find_by_host_and_database_name('localhost', 'private'), assigns(:search).zoom_db
    assert_not_nil assigns(:results)
    
    assert_response :success
    assert_template 'search/all'
  end

  def test_private_search_on_about_basket_is_declined_when_logged_in_and_not_a_member
    login_as(:bryan)
    
    get :all, :urlified_name => 'about', :controller_name_for_zoom_class => 'topics', :privacy_type => 'private'
    
    assert_response :redirect
  end

end
