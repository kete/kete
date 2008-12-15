require File.dirname(__FILE__) + '/../selenium_test_helper'

class VideoTest < Test::Unit::TestCase

  def setup
    @selenium = start_server
    login
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_add_video
    open "/site/video/new"
    assert_text_present "New video"
    click_and_wait "//input[@name='commit' and @value='Create']"
    assert_text_present "6 errors prohibited this video from being saved"
  end

  def test_edit_video
    open "/site/video/show/1"
    assert_text_present "Recording type"
    click_and_wait "link=Edit"
    select "video_basket_id", "label=About"
    type_from_hash { :video_title => 'Rails Example',
                     :video_tag_list => 'video,demo,test',
                     :video_version_comment => 'This is an video edit test.' }
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present ["Video was successfully updated.",
                         "Kete: About",
                         "Rails Example",
                         "Tags: test, demo, video"]
    click_and_wait "link=Edit"
    select "video_basket_id", "label=Site"
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present "Video was successfully updated."
  end

end
