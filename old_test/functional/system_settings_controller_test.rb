require File.dirname(__FILE__) + '/../test_helper'

class SystemSettingsControllerTest < ActionController::TestCase

  include KeteTestFunctionalHelper

  def setup
    @base_class = "SystemSettings"
    load_test_environment
  end

end
