# frozen_string_literal: true

require File.dirname(__FILE__) + '/selenium_test_helper'

class ConfigurationTest < ActionController::IntegrationTest
  context "An unconfigured Kete instance" do
    should "allow successful installation from start to finish" do
      visit "/"
      body_should_contain "Please enter the default administrator account login and password
                           to continue to configuration of the site."
      fill_in 'login', :with => 'admin'
      fill_in 'password', :with => 'test'
      click_button 'Log in'

      sleep 3

      body_should_contain 'Logged in successfully', :dump_response => true
      click_button 'Change password'

      body_should_contain 'Change password'
      fill_in 'old_password', :with => 'test'
      fill_in 'password', :with => 'kete'
      fill_in 'password_confirmation', :with => 'kete'
      click_button 'Change password'

      body_should_contain 'Password changed'
      click_link 'Server'
      fill_in 'setting_2_value', :with => 'Kete Test Setup'
      fill_in 'setting_3_value', :with => 'localhost'
      fill_in 'setting_5_value', :with => 'test@kete.net.nz'
      fill_in 'setting_6_value', :with => 'test@kete.net.nz'
      click_button 'Save'
      click_link 'System'
      click_button 'Save'
      body_should_contain 'All required settings are complete.'
      click_button 'Next'

      click_link 'set up Search Engine'
      click_button 'Save'
      click_button 'Start'
      click_button 'Finish'

      body_should_contain 'Final Configuration Step'
      Webrat.stop_app_server
      sleep 3
      Webrat.start_app_server
      sleep 3
      click_button 'Prime Search Engine'
      sleep 20
      body_should_contain 'Search Engine has been primed.'
      click_button 'Reload Site'
      body_should_contain 'Introduction'
    end
  end
end
