require File.dirname(__FILE__) + '/../test_helper'

class SampleTest < Test::Unit::TestCase
  def setup
    @selenium = Selenium::SeleniumDriver.new(SELENIUM_SERVER_HOST,
                                             SELENIUM_SERVER_PORT,
                                             SELENIUM_SERVER_BORWSER,
                                             SELENIUM_SERVER_BASE_URL,
                                             SELENIUM_SERVER_TIMEOUT);
    @selenium.start
  end

  def teardown
    @selenium.stop
  end

  def test_root_url_responds_and_has_correct_title
    open "/"
    assert_equal SITE_NAME, get_title
  end
end
