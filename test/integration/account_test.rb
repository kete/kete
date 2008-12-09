require File.dirname(__FILE__) + '/integration_test_helper'

class AccountTest < ActionController::IntegrationTest
  
  def test_log_in_as_admin
    visit "/"
    click_link "Login"
    fill_in "login", :with => "admin"
    fill_in "password", :with => "test"
    click_button "Log in"
    
    assert response.body.include?("<div>Logged in successfully</div>")
  end
  
end