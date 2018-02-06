# frozen_string_literal: true

require File.dirname(__FILE__) + '/integration_test_helper'

class RegisterTest < ActionController::IntegrationTest
  context "When a user registers, they" do
    setup do
      visit '/site/account/signup'
    end

    should "get errors when not all fields are filled in correctly" do
      fields = { 
        :user_login => 'tete',
        :user_email => 'test@kete.net.nz',
        :user_password => 'test',
        :user_password_confirmation => 'test',
        :user_display_name => 'Test',
        :user_security_code => 'SECURITY' 
      }
      fields.each { |name, value| fill_in name.to_s, :with => '' }
      click_button 'Sign up'
      body_should_contain '11 errors prohibited this user from being saved'
      fields.each { |name, value| fill_in name.to_s, :with => value }
      check 'user_agree_to_terms'
      click_button 'Sign up'
      body_should_contain '1 error prohibited this user from being saved'
      body_should_contain 'Security code : Your security question answer failed. Please try again.'
    end
  end

  context "When a user views signup form, the user" do
    should "get an option to use text question if site is configured to provide all captchas (the default)" do
      # all is the default for captcha type setting
      assert_equal CAPTCHA_TYPE, 'all'
      visit '/site/account/signup'
      body_should_contain 'Security Code: Please enter the text from the image to the right'
      body_should_contain 'non-image security question'
    end

    should "if they have chosen question captcha, get question version of captcha" do
      visit '/site/account/signup?captcha_type=question'
      body_should_not_contain 'Security Code: Please enter the text from the image to the right'
      body_should_not_contain 'non-image security question'
      body_should_contain "brain_buster_captcha"
    end

    should "get text question if site is configured to only provide question captcha" do
      configure_environment do
        set_constant :CAPTCHA_TYPE, 'question'
      end

      visit '/site/account/signup'

      body_should_not_contain 'non-image security question'
      body_should_not_contain 'Security Code: Please enter the text from the image to the right'
      body_should_contain "brain_buster_captcha"
    end

    should "get an image captcha if site is configured to only provide image captcha" do
      configure_environment do
        set_constant :CAPTCHA_TYPE, 'image'
      end

      visit '/site/account/signup'

      body_should_not_contain 'non-image security question'
      body_should_contain 'Security Code: Please enter the text from the image to the right'
    end

    teardown do
      configure_environment do
        set_constant :CAPTCHA_TYPE, 'all'
      end
    end
  end
end
