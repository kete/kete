require File.dirname(__FILE__) + '/integration_test_helper'

class ContributionsTest < ActionController::IntegrationTest
  context "When a topic has contributions" do
    setup do
      add_admin_as_super_user
      login_as('admin')
      @topic = new_topic
    end

    context "and the contributions/versions become out of sync" do
      setup do
        # This is the easiest way to cause problems, making versions without a contributor
        @topic.update_attribute(:title, 'Out of sync title 1')
        @topic.update_attribute(:title, 'Out of sync title 2')
      end

      context "and you view the history page in production mode, it" do
        setup do
          enable_production_mode
          # visit a page in Webrat that returns a 500 raises an error which stops this test. But we are wanting an
          # error 500, so instead, visit in a begin/rescue so we can continue to run the tests
          begin
            visit "/site/topics/history/#{@topic.id}"
          rescue
          end
        end

        teardown do
          disable_production_mode
        end

        should "display a nice error 500 page" do
          body_should_contain "500 Error!"
          body_should_contain "Oops! An error has prevented this page from loading."
        end
      end

      context "and you view the history page in development mode, it" do
        setup do
          # visit a page in Webrat that returns a 500 raises an error which stops this test. But we are wanting an
          # error 500, so instead, visit in a begin/rescue so we can continue to run the tests
          begin
            visit "/site/topics/history/#{@topic.id}"
          rescue
          end
        end

        should "display a backtrace with a meaningful raise" do
          body_should_contain "It looks like there is no contributor associated with version 2 of Topic #{@topic.id}."
        end
      end
    end
  end
end
