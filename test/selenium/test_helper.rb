require File.dirname(__FILE__) + '/../test_helper'
require "test/unit"
require File.dirname(__FILE__) + '/ruby-bindings/selenium'

SELENIUM_SERVER_HOST = '0.0.0.0'
SELENIUM_SERVER_PORT = 4444
SELENIUM_SERVER_BROWSER = '*firefox'
SELENIUM_SERVER_TIMEOUT = 10000

SELENIUM_WEB_SERVER_URL = 'http://kete_trunk'
SELENIUM_WEB_SERVER_PORT = '3001'
SELENIUM_WEB_SERVER_PATH = "#{SELENIUM_WEB_SERVER_URL}:#{SELENIUM_WEB_SERVER_PORT}"

require File.dirname(__FILE__) + '/server_controls'
include ServerControls
SeleniumRCServer.start
SeleniumWebServer.start

class Test::Unit::TestCase
  include SeleniumHelper
end
