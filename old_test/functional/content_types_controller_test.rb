# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

class ContentTypesControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  def setup
    @base_class = "ContentTypes"
    load_test_environment
  end
end
