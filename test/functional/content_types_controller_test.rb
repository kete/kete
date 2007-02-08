require File.dirname(__FILE__) + '/../test_helper'
require 'content_types_controller'

# Re-raise errors caught by the controller.
class ContentTypesController; def rescue_action(e) raise e end; end

class ContentTypesControllerTest < Test::Unit::TestCase
  def setup
    @controller = ContentTypesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
