require File.dirname(__FILE__) + '/integration_test_helper'

class SiteLockdownAuthTest < ActionController::IntegrationTest

  context "When a site has http credentials, it" do

    setup do
      configure_environment do
        set_constant :SITE_LOCKDOWN, { :username => 'test', :password => 'test' }
      end
    end

    teardown do
      configure_environment do
        set_constant :SITE_LOCKDOWN, {}
      end
    end

    should "require that the viewer login" do
      basic_auth 'test', 'test'
      visit "/"
      body_should_not_contain 'HTTP Basic: Access denied.'
      body_should_contain 'Kete'
    end

    should "not allow those with invalid credentials" do
      visit "/"
      body_should_not_contain 'Kete'
      body_should_contain 'HTTP Basic: Access denied.'
    end

  end

  context "When a site does not have HTTP Auth Credentials, it" do

    setup do
      configure_environment do
        set_constant :SITE_LOCKDOWN, {}
      end
    end

    should "not require that the viewer login" do
      visit "/"
      body_should_not_contain 'HTTP Basic: Access denied.'
      body_should_contain 'Kete'
    end

  end

end