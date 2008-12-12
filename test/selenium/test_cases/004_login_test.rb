require File.dirname(__FILE__) + '/../selenium_test_helper'

class LoginTest < Test::Unit::TestCase
  def setup
    @selenium = start_server
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_login
    login # this method is used often that its contents
          # have been wrapped inside a method in test_helper.rb
  end
end
