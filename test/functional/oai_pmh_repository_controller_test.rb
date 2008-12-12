require File.dirname(__FILE__) + '/../test_helper'

class OaiPmhRepositoryControllerTest < ActionController::TestCase

  include KeteTestFunctionalHelper

  def setup
    @base_class = "OaiPmhRepository"
    load_test_environment
  end

end