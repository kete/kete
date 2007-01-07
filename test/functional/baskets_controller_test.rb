require File.dirname(__FILE__) + '/../test_helper'
require 'baskets_controller'

# Re-raise errors caught by the controller.
class BasketsController; def rescue_action(e) raise e end; end

class BasketsControllerTest < Test::Unit::TestCase
  fixtures :baskets

  def setup
    @controller = BasketsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = baskets(:first).id
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'list'
  end

  def test_list
    get :list

    assert_response :success
    assert_template 'list'

    assert_not_nil assigns(:baskets)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:basket)
    assert assigns(:basket).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:basket)
  end

  def test_create
    num_baskets = Basket.count

    post :create, :basket => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_baskets + 1, Basket.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:basket)
    assert assigns(:basket).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Basket.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Basket.find(@first_id)
    }
  end
end
