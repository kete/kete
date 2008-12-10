require File.dirname(__FILE__) + '/integration_test_helper'

class AccountTest < ActionController::IntegrationTest

  context "A User" do

    setup do
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

  end

end
