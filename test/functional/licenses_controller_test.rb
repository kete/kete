require File.dirname(__FILE__) + '/../test_helper'

class LicensesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:licenses)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_license
    assert_difference('License.count') do
      post :create, :license => { }
    end

    assert_redirected_to license_path(assigns(:license))
  end

  def test_should_show_license
    get :show, :id => licenses(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => licenses(:one).id
    assert_response :success
  end

  def test_should_update_license
    put :update, :id => licenses(:one).id, :license => { }
    assert_redirected_to license_path(assigns(:license))
  end

  def test_should_destroy_license
    assert_difference('License.count', -1) do
      delete :destroy, :id => licenses(:one).id
    end

    assert_redirected_to licenses_path
  end
end
