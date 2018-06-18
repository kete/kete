# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_test_helper'

# for testing features that allow theme overriding
# such as CSS classes existing, etc.
class ThemeSupportTest < ActionController::IntegrationTest
  context "When there are more than 3 baskets on a site" do
    setup do
      @baskets = []
      4.times { |i| @baskets << create_new_basket({ :name => "basket #{i}" }) }
    end

    should "have more-baskets class for the more link to the baskets index page" do
      visit "/"
      body_should_contain "more-baskets"
    end

    teardown do
      @baskets.each { |b| b.destroy }
    end
  end
end
