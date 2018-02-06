# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

class ZoomDbsControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "ZoomDbs"
    load_test_environment
  end
end
