require File.dirname(__FILE__) + '/integration_test_helper'

class AccountTest < ActionController::IntegrationTest

  context "A User" do

    setup do
      add_paul_as_regular_user
    end

    should "be able to login" do
      login_as('paul')
      body_should_contain "Logged in successfully"
      url_should_contain "/site/all/topics"
      body_should_contain "Results in topics"
    end

    should "should have details displayed on the menu" do
      login_as('paul')
      body_should_contain "paul"
      body_should_contain "Logout"
    end

    should "fail login with incorrect credentials" do
      login_as('incorrect', 'login', { :should_fail_login => true })
      body_should_contain "Your password or login do not match our records. Please try again."
    end

    should "be able to logout once logged in" do
      login_as('paul')
      body_should_contain "Logged in successfully"
      logout
      url_should_contain "/site/all/topics"
      body_should_contain "Results in topics"
    end

    should "be redirected back to last tried location when logged in" do
      visit "/site/baskets/choose_type"
      login_as('paul', 'test', { :navigate_to_login => false })
      url_should_contain "/site/baskets/choose_type"
      body_should_contain "What would you like to add?"
    end

    context "when homepage slideshow controls are on" do

      setup do
        @@site_basket.update_attribute(:index_page_image_as, 'random')
        login_as('paul')
        @item1 = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
        @item2 = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
        @item3 = new_still_image { attach_file "image_file_uploaded_data", "white.jpg" }
      end

      teardown do
        @@site_basket.update_attribute(:index_page_image_as, '')
      end

      should "not have the slideshow overide their return_to when logging in" do
        logout
        visit "/"
        visit "/site/account/login"
        login_as('paul', 'test', { :navigate_to_login => false })
        url_should_contain Regexp.new("/$")
      end

    end

    context "when private items are enabled" do

      setup do
        @@site_basket.update_attribute(:show_privacy_controls, true)
        login_as('paul')
        @item = new_still_image({ :private_true => true, :file_private_true => true }) { attach_file "image_file_uploaded_data", "white.jpg" }
      end

      teardown do
        @@site_basket.update_attribute(:show_privacy_controls, false)
      end

      should "not have the private item overide their return_to when logging in" do
        logout
        visit "/site/images/show/#{@item.to_param}"
        body_should_contain 'No Public Version Available'
        visit "#{@item.original_file.public_filename}"
        body_should_contain 'Error 401: Unauthorized'
        visit "/site/account/login"
        login_as('paul', 'test', { :navigate_to_login => false })
        url_should_contain "/site/images/show/#{@item.id}"
      end

    end

  end

end
