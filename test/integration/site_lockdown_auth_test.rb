require File.dirname(__FILE__) + '/integration_test_helper'

class SiteLockdownAuthTest < ActionController::IntegrationTest

  pages = ['/',
           '/site/all/topics',
           '/site/baskets/choose_type',
           '/site/all/topics/rss.xml',
           '/about/topics/show/1']

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
      pages.each do |page|
        basic_auth 'test', 'test'
        visit page
        body_should_not_contain 'HTTP Basic: Access denied.'
        body_should_contain 'Kete'
      end
    end

    should "not allow those with invalid credentials" do
      pages.each do |page|
        visit page
        body_should_not_contain 'Kete'
        body_should_contain 'HTTP Basic: Access denied.'
      end
    end

  end

  context "When a site does not have HTTP Auth Credentials, it" do

    setup do
      configure_environment do
        set_constant :SITE_LOCKDOWN, {}
      end
    end

    should "not require that the viewer login" do
      pages.each do |page|
        visit page
        body_should_not_contain 'HTTP Basic: Access denied.'
        body_should_contain 'Kete'
      end
    end

  end

end