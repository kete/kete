require 'test/unit'
require File.join(File.dirname(__FILE__), 'test_helper')

# our test model
require File.join(File.dirname(__FILE__), 'fixtures/document')

class ConvertAttachmentToTest < Test::Unit::TestCase

  # test that we have required software
  REQUIRED_COMMANDS = %w(pdftohtml pdftotext wvWare lynx)

  def test_required_commands
    REQUIRED_COMMANDS.each do |command|
      assert_not_nil `which #{command}`, "convert_attachment_to plugin: #{command} not found, is it installed?"
    end
  end

  # test methods that do the conversions
  def test_convert_from_pdf_to_html
    to_html_doc = DocumentToHtml.new(:title => 'test document',
                                     :uploaded_data => fixture_file_upload('/files/test.pdf', 'application/pdf'))
    to_html_doc.save
    to_html_doc.reload

    assert_equal File.read(File.join(File.dirname(__FILE__), 'fixtures/files/to_html.html')), to_html_doc.description, "convert_attachment_to plugin: pdf to html results in unexpected value."
  end

  def test_convert_from_pdf_to_text
    to_text_doc = DocumentToText.new(:title => 'test document',
                                     :uploaded_data => fixture_file_upload('/files/test.pdf', 'application/pdf'))
    to_text_doc.save
    to_text_doc.reload

    assert_equal File.read(File.join(File.dirname(__FILE__), 'fixtures/files/to_text.txt')), to_text_doc.description, "convert_attachment_to plugin: pdf to text results in unexpected value."
  end

  def test_convert_from_msword_to_html
    to_html_doc = DocumentToHtml.new(:title => 'test document',
                                     :uploaded_data => fixture_file_upload('/files/test.doc', 'application/msword'))
    to_html_doc.save
    to_html_doc.reload

    assert_equal File.read(File.join(File.dirname(__FILE__), 'fixtures/files/msword_to_html.html')), to_html_doc.description, "convert_attachment_to plugin: pdf to html results in unexpected value."
  end

  def test_convert_from_msword_to_text
    to_text_doc = DocumentToText.new(:title => 'test document',
                                     :uploaded_data => fixture_file_upload('/files/test.doc', 'application/msword'))
    to_text_doc.save
    to_text_doc.reload

    assert_equal File.read(File.join(File.dirname(__FILE__), 'fixtures/files/msword_to_text.txt')), to_text_doc.description, "convert_attachment_to plugin: pdf to text results in unexpected value."
  end

  def test_convert_from_html_to_html
    to_html_doc = DocumentToHtml.new(:title => 'test document',
                                     :uploaded_data => fixture_file_upload('/files/test.html', 'text/html'))
    to_html_doc.save
    to_html_doc.reload

    assert_equal File.read(File.join(File.dirname(__FILE__), 'fixtures/files/html_to_html.html')), to_html_doc.description, "convert_attachment_to plugin: html to html results in unexpected value."
  end

  def test_convert_from_html_to_text
    to_text_doc = DocumentToText.new(:title => 'test document',
                                     :uploaded_data => fixture_file_upload('/files/test.html', 'text/html'))
    to_text_doc.save
    to_text_doc.reload

    assert_equal File.read(File.join(File.dirname(__FILE__), 'fixtures/files/to_text.txt')), to_text_doc.description, "convert_attachment_to plugin: html to text results in unexpected value."
  end

  def test_convert_from_text_to_html
    to_html_doc = DocumentToHtml.new(:title => 'test document',
                                     :uploaded_data => fixture_file_upload('/files/test.txt', 'text/plain'))
    to_html_doc.save
    to_html_doc.reload

    assert_equal File.read(File.join(File.dirname(__FILE__), 'fixtures/files/text_to_html.html')), to_html_doc.description, "convert_attachment_to plugin: text to html results in unexpected value."
  end

  def test_convert_from_text_to_text
    to_text_doc = DocumentToText.new(:title => 'test document',
                                     :uploaded_data => fixture_file_upload('/files/test.txt', 'text/plain'))
    to_text_doc.save
    to_text_doc.reload

    assert_equal File.read(File.join(File.dirname(__FILE__), 'fixtures/files/to_text.txt')), to_text_doc.description, "convert_attachment_to plugin: text to text results in unexpected value."
  end

  def test_do_conversion_as_separate_step
    to_text_doc = DocumentToTextManualConvert.new(:title => 'test document',
                                     :uploaded_data => fixture_file_upload('/files/test.txt', 'text/plain'))
    to_text_doc.save
    to_text_doc.reload

    assert_nil to_text_doc.description, "convert_attachment_to plugin: expected that target attribute should be empty, conversion shouldn't have happened yet."

    to_text_doc.do_conversion
    to_text_doc.reload

    assert_equal File.read(File.join(File.dirname(__FILE__), 'fixtures/files/to_text.txt')), to_text_doc.description, "convert_attachment_to plugin: text to text results in unexpected value after do_conversion."
  end
end
