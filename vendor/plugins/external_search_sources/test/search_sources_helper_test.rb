require 'test_helper'

class Entry
  cattr_accessor :title, :summary, :media_thumbnail, :enclosure
end

def search_sources; Array.new; end

class SearchSourcesHelperTest < ActionView::TestCase

  test "The display_search_sources helper should return nothing if no search sources exist" do
    assert_equal '', display_search_sources('test')
  end

  test "The search_source_title_for helper should return an trucated summary of the entry if one is present" do
    entry = Entry.new
    entry.title = nil

    assert_equal '', search_source_title_for(entry)

    entry.title = 'This is a summary for testing purposes'
    assert_equal entry.title, search_source_title_for(entry)
    assert_equal 'This is...', search_source_title_for(entry, 10)
  end

  test "The search_source_image_for helper should return an image tag" do
    entry = Entry.new
    entry.title = "Test Title"

    entry.enclosure = "http://example.com/image1.jpg"
    assert_equal '<img alt="Test Title. " height="50" src="http://example.com/image1.jpg" title="Test Title. " width="50" />', search_source_image_for(entry)

    entry.media_thumbnail = "http://example.com/image2.jpg"
    assert_equal '<img alt="Test Title. " height="50" src="http://example.com/image2.jpg" title="Test Title. " width="50" />', search_source_image_for(entry)
  end

end
