require File.dirname(__FILE__) + '/../selenium_test_helper'

class SampleTest < Test::Unit::TestCase

  def setup
    @selenium = start_server
    login
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_root_url_responds_and_has_correct_title
    open "/"
    assert_equal "Login to Kete", get_title
  end

end
