require File.dirname(__FILE__) + '/../test_helper'
require 'web_links_controller'

# Re-raise errors caught by the controller.
class WebLinksController; def rescue_action(e) raise e end; end

class WebLinksControllerTest < Test::Unit::TestCase
  # preloaded fixtures
  def setup
    @controller = WebLinksController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
