require File.dirname(__FILE__) + '/integration_test_helper'

class RegisterTest < ActionController::IntegrationTest

  context "When a user registers, they" do

    setup do
      visit '/site/account/signup'
    end

    should "get errors when not all fields are filled in correctly" do
      fields = { :user_login => 'tete',
                 :user_email => 'test@kete.net.nz',
                 :user_password => 'test',
                 :user_password_confirmation => 'test',
                 :user_extended_content_values_user_name => 'Test',
                 :user_security_code => 'SECURITY' }
      fields.each { |name,value| fill_in name.to_s, :with => '' }
      click_button 'Sign up'
      body_should_contain '10 errors prohibited this user from being saved'
      fields.each { |name,value| fill_in name.to_s, :with => value }
      check 'user_agree_to_terms'
      click_button 'Sign up'
      body_should_contain '1 error prohibited this user from being saved'
      body_should_contain 'Security code : Your security question answer failed - please try again.'
    end

  end

end
