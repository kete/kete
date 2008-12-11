require File.dirname(__FILE__) + '/integration_test_helper'

class AccountTest < ActionController::IntegrationTest

  context "A User" do

    setup do
      add_admin_as_super_user
    end

    should "be able to login" do
      login_as('admin')
      body_should_contain "Logged in successfully"
    end

    should "should have details displayed on the menu" do
      login_as('admin')
      body_should_contain "admin"
      body_should_contain "Logout"
    end

    should "fail login with incorrect credentials" do
      login_as('incorrect_login')
      body_should_contain "Your password or login do not match our records. Please try again."
    end

    should "be able to logout once logged in" do
      login_as('admin')
      body_should_contain "Logged in successfully"
      logout
      body_should_contain "Results in topics"
    end

    should "be redirected back to last tried location when logged in" do
      visit "/site/baskets/choose_type"
      login_as('admin', 'test', false)
      body_should_contain "What would you like to add? Where would you like to add it?"
      url_should_contain "/site/baskets/choose_type"
    end

  end

end
