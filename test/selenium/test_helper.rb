require File.dirname(__FILE__) + '/../test_helper'
require "test/unit"
require File.dirname(__FILE__) + '/ruby-bindings/selenium'

SELENIUM_SERVER_HOST = '0.0.0.0'
SELENIUM_SERVER_PORT = 4444
SELENIUM_SERVER_BORWSER = '*firefox'
SELENIUM_SERVER_BASE_URL = 'http://kete_trunk:3001'
SELENIUM_SERVER_TIMEOUT = 10000

begin
  ps = `ps aux | grep selenium`
  if ps.scan('selenium-server.jar').blank?
    raise unless system "java -jar #{File.dirname(__FILE__)}/server/selenium-server.jar > #{Rails.root}/log/selenium.log & sleep 5"
  end
rescue
  raise "ERROR: Could not find or start Selenium Server. Please start it manually."
end

class Test::Unit::TestCase
  include SeleniumHelper
end
