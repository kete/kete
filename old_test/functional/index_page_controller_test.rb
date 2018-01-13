require File.dirname(__FILE__) + '/../test_helper'

class IndexPageControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  include ImageSlideshowTestHelper

  def setup
    @base_class = "IndexPage"
    load_test_environment
  end
end
