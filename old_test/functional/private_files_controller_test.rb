require File.dirname(__FILE__) + '/../test_helper'

class PrivateFilesControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "PrivateFiles"
    load_test_environment
  end
end
