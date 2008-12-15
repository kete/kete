require File.dirname(__FILE__) + '/../selenium_test_helper'

class DocumentsTest < Test::Unit::TestCase

  def setup
    @selenium = start_server
    login
  end

  #def teardown
  #  @selenium.stop
  #end

  def test_add_document
    open "/site/documents/new"
    assert_text_present "New document"
    click_and_wait "//input[@name='commit' and @value='Create']"
    assert_text_present "6 errors prohibited this document from being saved"
  end

  def test_edit_document
    open "/site/documents/show/1"
    assert_text_present "Document type"
    click_and_wait "link=Edit"
    select "document_basket_id", "label=About"
    type_from_hash { :document_title => 'Rails Example',
                     :document_tag_list => 'document,demo,test',
                     :document_version_comment => 'This is an document edit test.' }
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present ["Document was successfully updated.",
                         "Kete: About",
                         "Rails Example",
                         "Tags: test, demo, document"]
    click_and_wait "link=Edit"
    select "document_basket_id", "label=Site"
    click_and_wait "//input[@name='commit' and @value='Save']"
    assert_text_present "Document was successfully updated."
  end

end
