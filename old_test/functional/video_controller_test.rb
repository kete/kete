require File.dirname(__FILE__) + '/../test_helper'

class VideoControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "Video"
    load_test_environment
  end
end
