require File.dirname(__FILE__) + '/../test_helper'
require 'video_controller'

# Re-raise errors caught by the controller.
class VideoController; def rescue_action(e) raise e end; end

class VideoControllerTest < Test::Unit::TestCase
  # fixtures are preloaded
  def setup
    @controller = VideoController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
