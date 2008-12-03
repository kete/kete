require File.dirname(__FILE__) + '/../test_helper'

class SampleTest < Test::Unit::TestCase
  def setup
    @selenium = Selenium::SeleniumDriver.new(SELENIUM_SERVER_HOST, SELENIUM_SERVER_PORT, SELENIUM_SERVER_BROWSER, SELENIUM_WEB_SERVER_PATH, SELENIUM_SERVER_TIMEOUT);
    @selenium.start
    @selenium.set_speed(2000)
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_configuration_of_kete_runs_successfully
    # Open up the root path
    open "/"
    assert is_text_present("Please enter the default administrator account login and password to continue to configuration of the site.")
    type "login", "admin"
    type "password", "test"
    click "commit"
    wait_for_page_to_load 10000
    assert is_text_present("Logged in successfully")
    assert is_text_present("You should change the default administrator account's password.")
    click "//input[@value='Change password']"
    wait_for_page_to_load 10000
    type "old_password", "test"
    type "password", "kete"
    type "password_confirmation", "kete"
    click "commit"
    wait_for_page_to_load 10000
    assert is_text_present("Configure")
    click "link=Server"
    sleep 2
    type "setting_3_value", "Kete Development Setup"
    type "setting_5_value", "test@kete.net.nz"
    type "setting_6_value", "test@kete.net.nz"
    click "commit"
    sleep 2
    assert is_element_present("//img[@alt='completed']")
    click "link=System"
    sleep 2
    click "commit"
    sleep 2
    assert is_element_present("//div[@id='System-check']/img")
    assert is_text_present("All required settings are complete.")
    click "//input[@name='commit' and @value='Next']"
    click "link=set up Search Engine"
    sleep 5
    click "commit"
    sleep 5
    assert is_text_present("The Search Engine needs to be started to continue.")
    click "//input[@name='commit' and @value='Start']"
    assert is_text_present("please click the 'finish' button.")
    click "//input[@name='commit' and @value='Finish']"
    assert is_text_present("Final Configuration Step")
    assert is_text_present("Before you continue, you must restart the kete application server!")
    SeleniumWebServer.restart
    click "prime-button"
    sleep 20
    assert is_text_present("Search Engine has been primed.")
    click "//input[@value='Reload Site']"
    wait_for_page_to_load 10000
    assert is_text_present("Introduction")
  end
end
