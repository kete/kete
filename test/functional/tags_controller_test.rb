require File.dirname(__FILE__) + '/../test_helper'

class TagsControllerTest < ActionController::TestCase

  include KeteTestFunctionalHelper

  def setup
    @base_class = "Tags"
    load_test_environment
  end

end
