require File.dirname(__FILE__) + '/../test_helper'
require 'configure_controller'

# Re-raise errors caught by the controller.
class ConfigureController; def rescue_action(e) raise e end; end

class ConfigureControllerTest < Test::Unit::TestCase
  def setup
    @controller = ConfigureController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
