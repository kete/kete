require File.dirname(__FILE__) + '/../selenium_test_helper'

class BasketsTest < Test::Unit::TestCase

  def setup
    @selenium = start_server
    login
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_add_basket
    open "/site/baskets/new"
    click_and_wait "//input[@name='commit' and @value='Create']"
    assert_text_present "1 error prohibited this basket from being saved"
    type_from_hash { :basket_name => 'Kete Test Basket' }
    select "settings_fully_moderated", "label=moderator views before item approved"
    click "//option[@value='true']"
    click "settings[moderated_except][]"
    click "//input[@name='settings[moderated_except][]' and @value='AudioRecording']"
    click "//input[@name='settings[moderated_except][]' and @value='Document']"
    click "basket_show_privacy_controls_true"
    click "basket_private_default_true"
    click "basket_file_private_default_true"
    click "basket_allow_non_member_comments_false"
    click_and_wait "//input[@name='commit' and @value='Create']"
    assert_text_present ["Basket was successfully created.",
                         "Kete Test Basket Edit"]
  end

  def test_edit_basket
    open "/site/baskets/edit/1"
    assert_text_present "Kete Test Basket Edit"
    type_from_hash { :basket_name => 'Edit Test Basket' }
    select "settings_fully_moderated", "label=moderation upon being flagged"
    click "//option[@value='false']"
    click "basket_show_privacy_controls_false"
    click "basket_private_default_false"
    click "basket_file_private_default_false"
    click "basket_allow_non_member_comments_true"
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present ["Basket was successfully updated.",
                         "Kete: Edit Test Basket",
                         "Keyword Search Edit Test Basket"]
    choose_cancel_on_next_confirmation
    click "link=delete this basket"
    assert_confirmation "Are you sure? All items in this basket will be deleted forever!"
  end

  def test_add_basket_member
    open "/site/baskets/edit/1"
    click_and_wait "link=Members"
    assert_text_present "Listing users"
    click_and_wait "//input[@name='commit' and @value='Search']"
    assert_text_present "Potential New Members"
    click "user_2-kete_add_checkbox"
    click_and_wait "//input[@name='commit' and @value='Add members']"
    assert_text_present "Successfully added new member."
  end

end
