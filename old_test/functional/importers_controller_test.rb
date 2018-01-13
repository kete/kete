require File.dirname(__FILE__) + '/../test_helper'

class ImportersControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "Importer"
    load_test_environment

    @topic = Topic.first
    @basket = @topic.basket

    User.find_by_login('admin').has_role('admin', @basket)
    User.find_by_login('bryan').has_role('moderator', @basket)
    User.find_by_login('arthur').has_role('member', @basket)
  end

  def test_import_accessible_to_basket_admins
    change_setting_on_basket(@basket, 'import_archive_set_policy', 'at least admin')
    login_as(:admin)
    get :new_related_set_from_archive_file, :urlified_name => @basket.urlified_name, :relate_to_topic => @topic
    assert_response :success
  end

  def test_import_accessible_to_basket_moderators
    change_setting_on_basket(@basket, 'import_archive_set_policy', 'at least moderator')
    login_as(:bryan)
    get :new_related_set_from_archive_file, :urlified_name => @basket.urlified_name, :relate_to_topic => @topic
    assert_response :success
  end

  def test_import_accessible_to_basket_members
    change_setting_on_basket(@basket, 'import_archive_set_policy', 'at least member')
    login_as(:arthur)
    get :new_related_set_from_archive_file, :urlified_name => @basket.urlified_name, :relate_to_topic => @topic
    assert_response :success
  end

  def test_import_not_accessible_to_non_members
    change_setting_on_basket(@basket, 'import_archive_set_policy', 'at least member')
    create_new_user(:login => 'joe')
    login_as(:joe)
    get :new_related_set_from_archive_file, :urlified_name => @basket.urlified_name, :relate_to_topic => @topic
    assert_response :redirect
    assert_redirected_to DEFAULT_REDIRECTION_HASH
  end

  def test_import_not_accessible_to_logged_out_users
    change_setting_on_basket(@basket, 'import_archive_set_policy', 'at least member')
    logout
    get :new_related_set_from_archive_file, :urlified_name => @basket.urlified_name, :relate_to_topic => @topic
    assert_response :redirect
    assert_redirected_to :urlified_name => 'site', :controller => 'account', :action => 'login'
  end

  private

  # Change a setting on a basket
  def change_setting_on_basket(basket_urlified_name, setting, value)
    @basket ||= Basket.find_by_urlified_name(basket_urlified_name)
    raise "#{basket_urlified_name} basket not found" if @basket.nil?
    @basket.settings[setting.to_sym] = value
  end
end
