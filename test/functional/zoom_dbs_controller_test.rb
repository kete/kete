require File.dirname(__FILE__) + '/../test_helper'
require 'zoom_dbs_controller'

# Re-raise errors caught by the controller.
class ZoomDbsController; def rescue_action(e) raise e end; end

class ZoomDbsControllerTest < Test::Unit::TestCase
  def setup
    @controller = ZoomDbsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
