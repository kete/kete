require File.dirname(__FILE__) + '/../test_helper'

class OaiPmhRepositorySetsControllerTest < ActionController::TestCase

  include KeteTestFunctionalHelper

  def setup
    @base_class = "OaiPmhRepositorySets"
    load_test_environment
  end

end
