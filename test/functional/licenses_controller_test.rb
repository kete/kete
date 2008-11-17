require File.dirname(__FILE__) + '/../test_helper'
require 'licenses_controller'

class LicensesController; def rescue_action(e) raise e end; end

class LicensesControllerTest < ActionController::TestCase
  include AuthenticatedTestHelper

  fixtures :licenses

  def setup
    @site_basket = Basket.find(:first)
    login_as :admin
  end

  def test_should_get_index
    get :index, :urlified_name => 'site', :controller => 'licenses'
    assert_response :success
    assert_not_nil assigns(:records)
  end

  def test_should_get_new
    get :new, :urlified_name => 'site'
    assert_response :success
  end

  # Kieran Pilkington, 2008/08/11
  # This will fail because we currently have no validations in place to make sure something is entered
  #def test_shouldnt_create_license
  #  assert_no_difference('License.count') do
  #    post :create, {:urlified_name => 'site', :record => {}}
  #  end
  #end

  def test_should_create_license
    assert_difference('License.count') do
      post :create, {:urlified_name => 'site', :record => { :name => 'test', :description => 'test', :url => "http://nothere.com", :is_available => true, :is_creative_commons => false }}
    end

    assert_redirected_to license_path(assigns(:license))
  end

  def test_should_show_license
    get :show, :id => licenses(:one).id, :urlified_name => 'site'
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => licenses(:one).id, :urlified_name => 'site'
    assert_response :success
  end

  def test_should_update_license
    put :update, {:id => licenses(:one).id, :urlified_name => 'site', :record => { :name => 'test', :description => 'test', :url => 'http://nothere.com', :is_available => true, :is_creative_commons => false }}
    assert_redirected_to license_path(assigns(:license))
  end

  def test_should_destroy_license
    assert_difference('License.count', -1) do
      delete :destroy, :id => licenses(:one).id, :urlified_name => 'site'
    end

    assert_redirected_to licenses_path
  end

  private

  def license_path(options = {})
    license_path_hash = { :urlified_name => 'site', :controller => 'licenses' }
    license_path_hash = license_path_hash.merge(options) unless options.nil?
    license_path_hash
  end

  def licenses_path(options = {})
    license_path_hash = { :urlified_name => 'site', :controller => 'licenses' }
    license_path_hash = license_path_hash.merge(options) unless options.nil?
    license_path_hash
  end
end
