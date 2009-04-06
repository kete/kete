require File.dirname(__FILE__) + '/../../test_helper'

class Entry
  cattr_accessor :title, :summary, :media_thumbnail, :enclosure
end

def search_sources; Array.new; end

class SearchSourcesHelperTest < ActionView::TestCase

  context "The display_search_sources helper" do

    should "return nothing if no search sources exist" do
      assert_equal '', display_search_sources
    end

  end

  context "The search_source_sort helper" do

    should "return a hash with two keys containing Arrays" do
      assert search_sources_sort([], 0).is_a?(Hash)
      assert search_sources_sort([], 0).keys.size == 2
      assert search_sources_sort([], 0)[:links].is_a?(Array)
      assert search_sources_sort([], 0)[:images].is_a?(Array)
    end

  end

  context "The search_source_title_for helper" do

    should "return an trucated summary of the entry if one is present" do
      entry = Entry.new

      assert_equal '', search_source_title_for(entry)

      entry.summary = 'This is a summary for testing purposes'
      assert_equal entry.summary, search_source_title_for(entry)
      assert_equal 'This is...', search_source_title_for(entry, 10)
    end

  end

  context "The search_source_image_for helper" do

    should "return an image tag" do
      entry = Entry.new
      entry.title = "Test Title"

      entry.enclosure = "http://example.com/image1.jpg"
      assert_equal '<img alt="Test Title. " height="50" src="http://example.com/image1.jpg" title="Test Title. " width="50" />', search_source_image_for(entry)

      entry.media_thumbnail = "http://example.com/image2.jpg"
      assert_equal '<img alt="Test Title. " height="50" src="http://example.com/image2.jpg" title="Test Title. " width="50" />', search_source_image_for(entry)
    end

  end

end
