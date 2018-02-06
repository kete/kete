# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

class SearchControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "Search"
    load_test_environment
  end

  def test_public_search_on_site_basket_works
    get :all, :urlified_name => 'site', :controller_name_for_zoom_class => 'topics'

    assert_equal false, @controller.send(:is_a_private_search?)
    assert_equal "public", @controller.send(:zoom_database)

    assert_response :success
    assert_nil assigns(:privacy)
    assert_equal ZoomDb.find_by_database_name('public'), assigns(:search).zoom_db
    assert_not_nil assigns(:results)

    assert_template 'search/all'
  end

  def test_public_search_on_about_basket_works
    get :all, :urlified_name => 'about', :controller_name_for_zoom_class => 'topics'

    assert_equal false, @controller.send(:is_a_private_search?)
    assert_equal "public", @controller.send(:zoom_database)

    assert_response :success
    assert_nil assigns(:privacy)
    assert_equal ZoomDb.find_by_database_name('public'), assigns(:search).zoom_db
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
    assert_equal ZoomDb.find_by_database_name('private'), assigns(:search).zoom_db
    assert_not_nil assigns(:results)
  end

  def test_private_search_on_about_basket_is_allowed_when_logged_in_and_member
    login_as(:admin)

    get :all, :urlified_name => 'about', :controller_name_for_zoom_class => 'topics', :privacy_type => 'private'

    assert_equal true, @controller.send(:is_a_private_search?)
    assert_equal "private", @controller.send(:zoom_database)

    assert assigns(:privacy)
    assert_equal ZoomDb.find_by_database_name('private'), assigns(:search).zoom_db
    assert_not_nil assigns(:results)

    assert_response :success
    assert_template 'search/all'
  end

  def test_private_search_on_about_basket_is_declined_when_logged_in_and_not_a_member
    login_as(:bryan)

    get :all, :urlified_name => 'about', :controller_name_for_zoom_class => 'topics', :privacy_type => 'private'

    assert_response :redirect
  end

  context "Saved searches functionality" do
    setup do
      @admin = User.find_by_login('admin')
      @urlified_name = Basket.site_basket.urlified_name
    end

    should "save the searches to the session when logged out" do
      logout
      get :all, :urlified_name => @urlified_name, :controller_name_for_zoom_class => 'topics'
      assert_equal 1, session[:searches].size
      assert session[:searches].first[:url] =~ /\/site\/all\/topics$/
    end

    should "save the searches to the database when logged in" do
      login_as(:admin)
      get :all, :urlified_name => @urlified_name, :controller_name_for_zoom_class => 'topics'
      assert_equal 1, @admin.searches.size
      assert @admin.searches.first.url =~ /\/site\/all\/topics$/
    end

    should "convert my session searches to stored searches when I log in" do
      logout
      get :all, :urlified_name => @urlified_name, :controller_name_for_zoom_class => 'topics'
      get :index, :urlified_name => @urlified_name, :controller => 'index_page'
      assert_equal 1, session[:searches].size
      @controller = AccountController.new
      post :login, :urlified_name => @urlified_name, :login => 'admin', :password => 'test'
      @controller = SearchController.new
      assert_equal 1, @admin.searches.size
      assert @admin.searches.first.url =~ /\/site\/all\/topics$/
    end
  end

  context "Parsing a date in preparation for searching on it" do
    setup do
      @beginning_date = "2010-01-01"
      @ending_date = "2010-12-31"
      @controller = SearchController.new
    end

    should "transform a full date value to properly formatted utc date that zebra can understand" do
      assert_equal Time.zone.parse("2010-10-17 00:00:01").utc.strftime("%Y-%m-%d"), @controller.send(:parse_date_into_zoom_compatible_format, "2010-10-17 00:00:01")
    end

    should "populate month and day from beginning of year when not specified" do
      assert_equal @beginning_date, @controller.send(:parse_date_into_zoom_compatible_format, "2010")
    end

    should "populate day from beginning of year when not specified" do
      assert_equal @beginning_date, @controller.send(:parse_date_into_zoom_compatible_format, "2010-01")
    end

    should "populate month and day from end of year when specified" do
      assert_equal @ending_date, @controller.send(:parse_date_into_zoom_compatible_format, "2010", :ending)
    end

    should "populate day from end of year when specified" do
      assert_equal @ending_date, @controller.send(:parse_date_into_zoom_compatible_format, "2010-12", :ending)
    end

    should "handle dates before 1900 when year, month, and day given" do
      assert_equal "1848-02-21", @controller.send(:parse_date_into_zoom_compatible_format, "1848-02-21 00:00:01")
    end

    should "handle dates before 1900 when month and day not given" do
      assert_equal "1848-01-01", @controller.send(:parse_date_into_zoom_compatible_format, "1848")
    end
  end
end
