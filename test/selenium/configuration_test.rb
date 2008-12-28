require File.dirname(__FILE__) + '/selenium_test_helper'

class ConfigurationTest < ActionController::IntegrationTest

  context "An unconfigured Kete instance" do

    should "require you login before configuring" do
      visit "/"
      body_should_contain "Login to Kete"
    end

  end

end
