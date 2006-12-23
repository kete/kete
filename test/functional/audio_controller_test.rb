require File.dirname(__FILE__) + '/../test_helper'
require 'audio_controller'

# Re-raise errors caught by the controller.
class AudioController; def rescue_action(e) raise e end; end

class AudioControllerTest < Test::Unit::TestCase
  fixtures :audio_recordings

  def setup
    @controller = AudioController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new

    @first_id = audio_recordings(:first).id
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

    assert_not_nil assigns(:audio_recordings)
  end

  def test_show
    get :show, :id => @first_id

    assert_response :success
    assert_template 'show'

    assert_not_nil assigns(:audio_recording)
    assert assigns(:audio_recording).valid?
  end

  def test_new
    get :new

    assert_response :success
    assert_template 'new'

    assert_not_nil assigns(:audio_recording)
  end

  def test_create
    num_audio_recordings = AudioRecording.count

    post :create, :audio_recording => {}

    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_equal num_audio_recordings + 1, AudioRecording.count
  end

  def test_edit
    get :edit, :id => @first_id

    assert_response :success
    assert_template 'edit'

    assert_not_nil assigns(:audio_recording)
    assert assigns(:audio_recording).valid?
  end

  def test_update
    post :update, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'show', :id => @first_id
  end

  def test_destroy
    assert_nothing_raised {
      AudioRecording.find(@first_id)
    }

    post :destroy, :id => @first_id
    assert_response :redirect
    assert_redirected_to :action => 'list'

    assert_raise(ActiveRecord::RecordNotFound) {
      AudioRecording.find(@first_id)
    }
  end
end
