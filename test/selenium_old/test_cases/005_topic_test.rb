require File.dirname(__FILE__) + '/../selenium_test_helper'

class TopicsTest < Test::Unit::TestCase

  def setup
    @selenium = start_server
    login
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_add_topic
    open "/site/topics/new"
    click_and_wait "//input[@name='commit' and @value='Choose']"
    assert_text_present "New topic"
    click_and_wait "//input[@name='commit' and @value='Create']"
    assert_text_present "1 error prohibited this topic from being saved"
    type_from_hash { :topic_title => 'New Topic',
                     :topic_short_summary => 'This is a new topic.',
                     :topic_description => 'This is a new topic used Selenium testing.',
                     :topic_tag_list => 'test,new,demo' }
    click_and_wait "//input[@name='commit' and @value='Create']"
    assert_text_present ["Topic was successfully created.",
                         "Topic: New Topic",
                         "Tags: test, new, demo"]
  end

  def test_edit_topic
    open "/site/topics/show/1"
    assert_text_present "Topic: New Topic"
    click_and_wait "link=Edit"
    select "topic_basket_id", "label=About"
    type_from_hash { :topic_title => 'Rails Example',
                     :topic_tag_list => 'topic,demo,test',
                     :topic_version_comment => 'This is a test edit.' }
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present ["Topic was successfully edited.",
                         "Kete: About",
                         "Rails Example",
                         "Tags: test, demo, topic"]
    click_and_wait "link=Edit"
    select "topic_basket_id", "label=Site"
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present "Topic was successfully edited."
  end

end
