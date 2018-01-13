require File.dirname(__FILE__) + '/../test_helper'

class AudioControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "Audio"
    load_test_environment
  end
end
