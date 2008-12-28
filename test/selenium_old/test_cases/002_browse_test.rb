require File.dirname(__FILE__) + '/../selenium_test_helper'

class BrowseTest < Test::Unit::TestCase
  def setup
    @selenium = start_server
    login
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_browsing_of_default_topics
    open "/"
    click_and_wait "link=Browse"
    assert_text_present ["Topics (15)",
                         "Web Links (1)"]
    open "/site/all/topics?number_of_results_per_page=5"
    click_and_wait "link=3"
    click_and_wait "link=1"
    open "/site/all/topics?number_of_results_per_page=10"
    assert_text_present "Showing 1-10 results of 14"
    click_and_wait "link=About Kete"
    assert_text_present "Topic: About Kete"
    click_and_wait "link=Help"
    click_and_wait "link=Privacy Policy"
    assert_text_present "Topic: Privacy Policy"
  end
end
