require File.dirname(__FILE__) + '/../test_helper'
require 'importers_controller'

# Re-raise errors caught by the controller.
class ImportersController; def rescue_action(e) raise e end; end

class ImportersControllerTest < Test::Unit::TestCase
  def setup
    @controller = ImportersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
