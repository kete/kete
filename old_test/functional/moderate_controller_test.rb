require File.dirname(__FILE__) + '/../test_helper'

class ModerateControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "Moderate"
    load_test_environment
  end
end
