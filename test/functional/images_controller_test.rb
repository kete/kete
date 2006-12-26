require File.dirname(__FILE__) + '/../test_helper'
require 'images_controller'

# Re-raise errors caught by the controller.
class ImagesController; def rescue_action(e) raise e end; end

class ImagesControllerTest < Test::Unit::TestCase
  fixtures :images

  def setup
    @controller = ImagesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = images(:first).id
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

    assert_not_nil assigns(:images)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:image)
    assert assigns(:image).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:image)
  end

  def test_create
    num_images = Image.count

    post :create, :image => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_images + 1, Image.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:image)
    assert assigns(:image).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      Image.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      Image.find(@first_id)
    }
  end
end
