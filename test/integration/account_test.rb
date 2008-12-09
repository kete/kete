require File.dirname(__FILE__) + '/integration_test_helper'

class AccountTest < ActionController::IntegrationTest

  context "A User" do

    setup do
      visit "/site/account/logout"
    end

    should "be able to login" do
      visit "/"
      click_link "Login"
      fill_in "login", :with => "admin"
      fill_in "password", :with => "test"
      click_button "Log in"
      assert response.body.include?("<div>Logged in successfully</div>")
    end

    should "fail login with incorrect credentials" do
      visit "/"
      click_link "Login"
      fill_in "login", :with => "bad"
      fill_in "password", :with => "details"
      click_button "Log in"
      assert response.body.include?("<div>Your password or login do not match our records. Please try again.</div>")
    end

  end

end
