require File.dirname(__FILE__) + '/integration_test_helper'
require File.join(File.dirname(__FILE__), '../factories')

class TopicPrivacyTest < ActionController::IntegrationTest
  context "A Kete instance" do
    
    setup do
      # Ensure a user account to log in with is present
      user = Factory(:user) unless User.find_by_login("joe")
      assert_kind_of User, User.find_by_login("joe")
      
      # Log in
      visit "/"
      click_link "Login"
      fill_in "login", :with => "joe"
      fill_in "password", :with => "test"
      click_button "Log in"
      assert response.body.include?("Logged in successfully"), "Should say logged in successfully"
    end
    
    should "be logged in as joe" do
      visit "/"
      assert response.body.include?("joe"), "Should display your login"
      assert response.body.include?("Logout"), "Should have log out link"
    end
    
  end
end