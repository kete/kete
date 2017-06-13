require File.dirname(__FILE__) + '/../test_helper'

class WebLinksControllerTest < ActionController::TestCase

  include KeteTestFunctionalHelper

  def setup
    @base_class = "WebLinks"
    load_test_environment
  end

end
