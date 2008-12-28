require File.dirname(__FILE__) + '/../selenium_test_helper'

class RegisterTest < Test::Unit::TestCase
  def setup
    @selenium = start_server
    logout
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_registration
    open "/site/account/signup"
    type_from_hash { :user_login => '',
                     :user_email => '',
                     :user_password => '',
                     :user_password_confirmation => '',
                     :user_user_name => '',
                     :user_security_code => '' }
    click_and_wait "//input[@name='commit' and @value='Sign up']"
    assert_text_present "10 errors prohibited this user from being saved"
    type_from_hash { :user_login => 'tete',
                     :user_email => 'test@kete.net.nz',
                     :user_password => 'test',
                     :user_password_confirmation => 'test',
                     :user_user_name => 'Test',
                     :user_security_code => 'SECURITY' }
    click "user_agree_to_terms"
    click_and_wait "//input[@name='commit' and @value='Sign up']"
    assert_text_present ["1 error prohibited this user from being saved",
                         "Security code : Your security question answer failed - please try again."]
  end
end
