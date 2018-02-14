# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

class ConfigureControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "Configure"
    load_test_environment
  end
end
