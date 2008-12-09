require File.dirname(__FILE__) + '/integration_test_helper'

class TopicPrivacyTest < ActionController::IntegrationTest
  context "A Kete instance" do
    
    setup do
      
      # Allow anyone to create baskets for the purposes of this test
      configure_environment do
        set_constant :BASKET_CREATION_POLICY, "open"
      end
      
      # Ensure a user account to log in with is present
      user = Factory(:user) unless User.find_by_login("joe")
      @user = User.find_by_login("joe")
      assert_kind_of User, @user
      
      @user.add_as_member_to_default_baskets
      
      # Log in
      visits "/"
      clicks_link "Login"
      fills_in "login", :with => "joe"
      fills_in "password", :with => "test"
      clicks_button "Log in"
      assert response.body.include?("Logged in successfully"), "Should say logged in successfully"
    end
    
    should "have open basket creation policy" do
      assert_equal "open", BASKET_CREATION_POLICY
    end
    
    should "be logged in as joe" do
      visits "/"
      assert response.body.include?("joe"), "Should display your login"
      assert response.body.include?("Logout"), "Should have log out link"
    end
    
    should "create a public topic" do
      visits "/site/baskets/choose_type"

      selects "Topic", :from => "new_item_controller"
      clicks_button "Choose"
      
      selects "Topic", :from => "topic[topic_type_id]"
      clicks_button "Choose"
      
      assert response.body.include?("New Topic")
      assert response.body.include?("Title")
      assert !response.body.include?("Private version")
    end
    
  end
end