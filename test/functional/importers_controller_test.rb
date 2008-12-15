require File.dirname(__FILE__) + '/../test_helper'

class ImportersControllerTest < ActionController::TestCase

  include KeteTestFunctionalHelper

  def setup
    @base_class = "Importers"
    load_test_environment
  end

end
