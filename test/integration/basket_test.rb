require File.dirname(__FILE__) + '/integration_test_helper'

class BasketTest < ActionController::IntegrationTest

  context "When you view a basket doesn't exist" do

    context "in production mode, it" do

      setup do
        enable_production_mode
        begin
          visit "/does_not_exist"
        rescue
        end
      end

      teardown do
        disable_production_mode
      end

      should "give a 404 (not blank page for error 500)" do
        body_should_contain "404 Error!"
      end

    end

    context "in development mode, it" do

      setup do
        begin
          visit "/does_not_exist"
        rescue
        end
      end

      should "give a backtrace with a meaningful raise" do
        body_should_contain "Couldn't find Basket with NAME=does_not_exist."
      end

    end

  end

end