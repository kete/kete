require File.dirname(__FILE__) + '/../selenium_test_helper'

class ImagesTest < Test::Unit::TestCase

  def setup
    @selenium = start_server
    login
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_add_image
    open "/site/images/new"
    assert_text_present "New image"
    click_and_wait "//input[@name='commit' and @value='Create']"
    assert_text_present "5 errors prohibited this image file from being saved"
  end

  def test_edit_image
    open "/site/images/show/1"
    assert_text_present "Original Filename"
    click_and_wait "link=Edit"
    select "still_image_basket_id", "label=About"
    type_from_hash { :still_image_title => 'Rails Example',
                     :still_image_tag_list => 'image,demo,test',
                     :still_image_version_comment => 'This is an image edit test.' }
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present ["Image was successfully updated.",
                         "Kete: About",
                         "Rails Example",
                         "Tags: test, demo, image"]
    click_and_wait "link=Edit"
    select "still_image_basket_id", "label=Site"
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present "Image was successfully updated."
  end

end
