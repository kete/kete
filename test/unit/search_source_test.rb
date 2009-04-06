require File.dirname(__FILE__) + '/../test_helper'

class SearchSourceTest < ActiveSupport::TestCase

  @@new_model = { :title => 'Test Search Source',
                  :source_type => 'feed',
                  :base_url => 'http://example.com/rss.xml?q=',
                  :limit => 5,
                  :cache_interval => 5 }

  should_validate_presence_of :title, :source_type, :base_url, :limit, :cache_interval

  context "The Search Source model" do

    should "contain a class var of acceptable source types" do
      assert_equal %w{ feed }, SearchSource.acceptable_source_types
    end

    should "have a method that returns a title based id for html element ids" do
      source = SearchSource.new(@@new_model)
      assert_equal 'test_search_source', source.title_id
    end

  end

end
