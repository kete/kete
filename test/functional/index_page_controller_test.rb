require File.dirname(__FILE__) + '/../test_helper'
require 'index_page_controller'

# Re-raise errors caught by the controller.
class IndexPageController; def rescue_action(e) raise e end; end

class IndexPageControllerTest < Test::Unit::TestCase
  def setup
    @controller = IndexPageController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
