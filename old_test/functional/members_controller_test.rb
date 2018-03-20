# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

class MembersControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "Members"
    load_test_environment
    login_as(:admin)
  end

  def test_list_accessable_to_anyone
    logout
    change_setting_on_basket('about', 'memberlist_policy', 'all users')
    get :list, :urlified_name => 'about'
    assert_response :success
  end

  def test_list_inaccessable_to_logged_out_users
    logout
    change_setting_on_basket('about', 'memberlist_policy', 'logged in')
    make_failed_attempt_to_memberlist
    change_setting_on_basket('about', 'memberlist_policy', 'at least member')
    make_failed_attempt_to_memberlist
  end

  def test_list_accessable_to_logged_in_users
    login_as(:bryan)
    change_setting_on_basket('about', 'memberlist_policy', 'logged in')
    get :list, :urlified_name => 'about'
    assert_response :success
  end

  def test_list_accessable_to_basket_members
    User.find_by_login('bryan').has_role('member', Basket.find_by_id(3))
    login_as(:bryan)
    change_setting_on_basket('about', 'memberlist_policy', 'at least member')
    get :list, :urlified_name => 'about'
    assert_response :success
  end

  def test_listing_type_member_for_all_but_admin
    login_as(:bryan)
    change_setting_on_basket('about', 'memberlist_policy', 'all users')
    get :list, :urlified_name => 'about', :type => 'pending'
    assert_equal 'member', assigns(:listing_type)
  end

  def test_listing_type_provided_for_admins
    login_as(:admin)
    get :list, :urlified_name => 'about', :type => 'pending'
    assert_equal 'pending', assigns(:listing_type)
  end

  def test_request_membership_needs_user_logged_in
    logout
    get :join, :urlified_name => 'about'
    assert_response :redirect
    assert_redirected_to "http://www.example.com/en/site/account/login"
  end

  def test_user_cannot_apply_if_already_has_role_in_basket
    User.find_by_login('bryan').has_role('member', Basket.first)
    change_setting_on_basket('site', 'basket_join_policy', 'open')
    login_as(:bryan)

    get :join, :urlified_name => 'site'
    assert_response :redirect
    assert_redirected_to "/site/"
    assert_equal "You already have a role in this basket or you have already applied to join.", flash[:error]
  end

  def test_user_can_apply_instantly_if_basket_public
    change_setting_on_basket('help', 'basket_join_policy', 'open')
    login_as(:bryan)

    get :join, :urlified_name => 'help'
    assert_response :redirect
    assert_redirected_to "/help/"
    assert_equal "You have joined the Help basket.", flash[:notice]

    # check that we were joined successfully by seeing if we can rejoin
    get :join, :urlified_name => 'help'
    assert_equal "You already have a role in this basket or you have already applied to join.", flash[:error]
  end

  def test_user_has_join_moderated_if_basket_policy_request
    change_setting_on_basket('about', 'basket_join_policy', 'request')
    login_as(:bryan)

    get :join, :urlified_name => 'about'
    assert_response :redirect
    assert_redirected_to "/about/"
    assert_equal "A basket membership request has been sent. You will get an email when it is approved.", flash[:notice]

    # check that we were joined successfully by seeing if we can rejoin
    get :join, :urlified_name => 'about'
    assert_equal "You already have a role in this basket or you have already applied to join.", flash[:error]
  end

  def test_user_cannot_apply_if_basket_private
    change_setting_on_basket('documentation', 'basket_join_policy', 'closed')
    login_as(:bryan)

    get :join, :urlified_name => 'documentation'
    assert_response :redirect
    assert_redirected_to "/documentation/"
    assert_equal "This basket isn't currently accepting join requests.", flash[:error]
  end

  def test_accept_membership
    bryan = User.find_by_login('bryan')
    bryan.has_role('membership_requested', Basket.find_by_id(3))
    get :change_request_status, :urlified_name => 'about', :id => bryan.id, :status => 'approved'
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal "#{bryan.user_name}'s membership request has been accepted.", flash[:notice]
  end

  def test_reject_membership
    bryan = User.find_by_login('bryan')
    bryan.has_role('membership_requested', Basket.find_by_id(3))
    get :change_request_status, :urlified_name => 'about', :id => bryan.id, :status => 'rejected'
    assert_response :redirect
    assert_redirected_to :action => 'list'
    assert_equal "#{bryan.user_name}'s membership request has been rejected.", flash[:notice]
  end

  private

  # used several times in the tests aboce
  def make_failed_attempt_to_memberlist
    get :list, :urlified_name => 'about'
    assert_response :redirect
    assert_redirected_to :controller => 'baskets', :action => 'permission_denied'
  end

  # Change a setting on a basket
  def change_setting_on_basket(basket_urlified_name, setting, value)
    @basket ||= Basket.find_by_urlified_name(basket_urlified_name)
    raise "#{basket_urlified_name} basket not found" if @basket.nil?
    @basket.settings[setting.to_sym] = value
  end
end
