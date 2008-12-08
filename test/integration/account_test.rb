require File.dirname(__FILE__) + '/../test_helper'

class AccountTest < ActionController::IntegrationTest
  
  def setup
    
    # Ensure we are past the configuration steps
    assert SystemSetting.count_by_sql("SELECT COUNT(*) FROM system_settngs") > 0
    
  end
  
  def test_log_in_as_admin
    visit "/"
    click_link "Login"
    fill_in "login", :with => "admin"
    fill_in "password", :with => "test"
    click_button "Log in"
    
    contain "<div>Logged in successfully</div>"
  end
  
end