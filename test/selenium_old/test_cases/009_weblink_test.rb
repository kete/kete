require File.dirname(__FILE__) + '/../selenium_test_helper'

class WebLinksTest < Test::Unit::TestCase

  def setup
    @selenium = start_server
    login
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_add_weblink
    open "/site/web_links/new"
    assert_text_present "New web link"
    click_and_wait "//input[@name='commit' and @value='Create']"
    assert_text_present "2 errors prohibited this web link from being saved"
    type_from_hash { :web_link_title => 'Rails Example',
                     :web_link_tag_list => 'test,new,demo',
                     :web_link_url => 'http://google.co.nz/' }
    click_and_wait "//input[@name='commit' and @value='Create']"
    assert_text_present ["Web Link was successfully created.",
                         "New Web Link",
                         "Tags: test, new, demo"]
  end

  def test_edit_weblink
    open "/site/web_links/show/1"
    assert_text_present "New Web Link"
    click_and_wait "link=Edit"
    select "web_link_basket_id", "label=About"
    type_from_hash { :web_link_title => 'Rails Example',
                     :web_link_tag_list => 'weblink,demo,test',
                     :web_link_version_comment => 'This is a test weblink edit.' }
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present ["WebLink was successfully updated.",
                         "Kete: About",
                         "Rails Example",
                         "Tags: test, demo, weblink"]
    click_and_wait "link=Edit"
    select "web_link_basket_id", "label=Site"
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present "WebLink was successfully updated."
  end

end
