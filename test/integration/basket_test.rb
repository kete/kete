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
    
    context "A new basket" do

      setup do
        add_sarah_as_super_user
        login_as('sarah')

        @basket = new_basket
      end

      should "be able to turn on full moderation" do
        
        # For some reason false != false ??
        assert_equal "false", @basket.settings[:fully_moderated].to_s
        
        visit "/site/baskets/edit/#{@basket.id}"
        select "moderator views before item approved", :from => "settings_fully_moderated"
        click_button "Update"
        body_should_contain "Basket was successfully updated."
        assert @basket.settings[:fully_moderated]
      end

      should "be able to turn off full moderation" do
        @basket.settings[:fully_moderated] = true
        @basket.save!
        assert @basket.settings[:fully_moderated]
        
        visit "/site/baskets/edit/#{@basket.id}"
        body_should_contain '<option value="true" selected="selected">moderator views before item approved</option>'
        select "moderation upon being flagged", :from => "settings_fully_moderated"
        click_button "Update"
        body_should_contain "Basket was successfully updated."
        assert_equal "false", @basket.settings[:fully_moderated].to_s
      end

    end

  end

end