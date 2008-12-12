require File.dirname(__FILE__) + '/../selenium_test_helper'

class ConfigurationTest < Test::Unit::TestCase

  def setup
    @selenium = start_server
    login
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_configuration_of_kete_runs_successfully
    open "/"
    assert_text_present "Please enter the default administrator account login and password to continue to configuration of the site."
    type_from_hash { :login => 'admin',
                     :password => 'test' }
    click_and_wait "commit"
    assert_text_present ["Logged in successfully",
                         "You should change the default administrator account's password."]
    click_and_wait "//input[@value='Change password']"
    type_from_hash { :old_password => 'test',
                     :password => 'kete',
                     :password_confirmation => 'kete' }
    click_and_wait "commit"
    assert_text_present "Configure"
    click_and_wait "link=Server", nil, 2
    type_from_hash { :setting_3_value => 'Kete Development Setup',
                     :setting_5_value => 'test@kete.net.nz',
                     :setting_6_value => 'test@kete.net.nz' }
    click_and_wait "commit", nil, 2
    assert is_element_present("//img[@alt='completed']")
    click_and_wait "link=System", nil, 2
    click_and_wait "commit", nil, 2
    assert is_element_present("//div[@id='System-check']/img")
    assert_text_present "All required settings are complete."
    click "//input[@name='commit' and @value='Next']"
    click_and_wait "link=set up Search Engine", nil, 5
    click_and_wait "commit", nil, 5
    assert_text_present "The Search Engine needs to be started to continue."
    click "//input[@name='commit' and @value='Start']"
    assert_text_present "please click the 'finish' button."
    click "//input[@name='commit' and @value='Finish']"
    assert_text_present ["Final Configuration Step",
                         "Before you continue, you must restart the kete application server!"]
    @selenium_web_server.restart
    click_and_wait "prime-button", nil, 20
    assert_text_present "Search Engine has been primed."
    click_and_wait "//input[@value='Reload Site']"
    assert_text_present "Introduction"
  end

end
