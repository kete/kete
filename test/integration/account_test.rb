require File.dirname(__FILE__) + '/integration_test_helper'

class AccountTest < ActionController::IntegrationTest

  context "A User" do

    setup do
      add_admin_as_super_user
    end

    should "be able to login" do
      login_as('admin', 'test')
      body_should_contain "Logged in successfully"
    end

    should "fail login with incorrect credentials" do
      login_as('bad', 'details')
      body_should_contain "Your password or login do not match our records. Please try again."
    end

    should "be able to logout once logged in" do
      login_as('admin', 'test')
      body_should_contain "Logged in successfully"
      logout
      body_should_contain "Results in topics"
    end
    
    should "be redirected back to last tried location when logged in" do
      visit "/site/baskets/choose_type"
      body_should_contain "Login to Kete"
      
      fill_in "login", :with => "admin"
      fill_in "password", :with => "test"
      click_button "Log in"
      
      body_should_contain "What would you like to add? Where would you like to add it?"
      assert request.url.include?("/site/baskets/choose_type")
    end
    
  end

end
