require File.dirname(__FILE__) + '/../test_helper'
require "test/unit"
require File.dirname(__FILE__) + '/ruby-bindings/selenium'

SELENIUM_SERVER_JARFILE = "#{Rails.root}/test/selenium/server/selenium-server.jar"
SELENIUM_SERVER_HOST = '0.0.0.0'
SELENIUM_SERVER_PORT = 4444
SELENIUM_SERVER_BROWSER = '*firefox'
SELENIUM_SERVER_TIMEOUT = 10000

SELENIUM_WEB_SERVER_URL = 'http://kete_trunk'
SELENIUM_WEB_SERVER_PORT = '3001'
SELENIUM_WEB_SERVER_PATH = "#{SELENIUM_WEB_SERVER_URL}:#{SELENIUM_WEB_SERVER_PORT}"

require File.dirname(__FILE__) + '/server_controls'
include ServerControls
@selenium_rc_server = SeleniumRCServer.new "#{File.dirname(__FILE__)}/server/selenium-rc-server.pid"
@selenium_rc_server.start
@selenium_web_server = SeleniumWebServer.new "#{File.dirname(__FILE__)}/server/selenium-web-server.pid"
@selenium_web_server.start

class Test::Unit::TestCase
  include SeleniumHelper

  def start_server
    @selenium = Selenium::SeleniumDriver.new(SELENIUM_SERVER_HOST,
                                             SELENIUM_SERVER_PORT,
                                             SELENIUM_SERVER_BROWSER,
                                             SELENIUM_WEB_SERVER_PATH,
                                             SELENIUM_SERVER_TIMEOUT)
    @selenium.start
    @selenium.set_speed(2000)
    @selenium
  end

  def click_and_wait(locator, wait_time=10, sleep_time=nil) # delay is passed in as seconds
    click(locator)
    wait_for_page_to_load (1000 * wait_time) unless wait_time.nil? # wait method needs milliseconds
    sleep sleep_time unless sleep_time.nil? # sleep method needs seconds
  end

  def type_from_hash(values)
    values.each do |key,value|
      type key.to_s, value.to_s
    end
  end

  def logout
    open "/site/account/logout"
  end

  def login_as(username='admin', password='kete')
    logout
    open "/site/account/login"
    type_from_hash { :login => username,
                     :password => password }
    click "remember_me"
    click_and_wait "//input[@name='commit' and @value='Log in']"
    assert is_text_present("Logged in successfully")
  end
  alias login, login_as

  def assert_text_present(values)
    values = [values] if values.kind_of?(String)
    values.each do |value|
      assert is_element_present(value)
    end
  end

end
