# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

class TopicsControllerTest < ActionController::TestCase
  include KeteTestFunctionalHelper

  include ImageSlideshowTestHelper

  def setup
    @base_class = "Topics"
    load_test_environment
  end
end
