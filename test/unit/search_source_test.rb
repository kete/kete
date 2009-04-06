require File.dirname(__FILE__) + '/../test_helper'

class SearchSourceTest < ActiveSupport::TestCase

  @@new_model = { :title => 'Test Search Source',
                  :source_type => 'feed',
                  :base_url => 'http://example.com/rss.xml?q=',
                  :more_link_base_url => 'http://example.com/?q=',
                  :limit => 5,
                  :cache_interval => 5 }

  should_validate_presence_of :title, :source_type, :base_url, :limit, :cache_interval
  should_validate_numericality_of :limit, :cache_interval

  context "The Search Source model" do

    should "contain a class var of acceptable source types" do
      assert_equal %w{ feed }, SearchSource.acceptable_source_types
    end

    should "require that source_type be in SearchSource.acceptable_source_types" do
      source = SearchSource.new(@@new_model.merge(:source_type => 'invalid'))
      assert !source.valid?
      assert 'must be one of the following: feed', source.errors['source_type']
    end

    should "require that base url be of protocol type http" do
      source = SearchSource.new(@@new_model.merge(:base_url => 'feed://example.com/rss.xml'))
      assert !source.valid?
      assert 'requires an http protocol', source.errors['source_type']
    end

    should "have a method that returns a title based id for html element ids" do
      source = SearchSource.new(@@new_model)
      assert_equal 'test_search_source', source.title_id
    end

    should "have an authorized_for? method that works with alongside ActiveScaffold" do
      source1 = SearchSource.create(@@new_model)
      source2 = SearchSource.create(@@new_model)
      source3 = SearchSource.create(@@new_model)

      assert !source1.authorized_for?(:action => :move_higher)
      assert source1.authorized_for?(:action => :move_lower)

      assert source2.authorized_for?(:action => :move_higher)
      assert source2.authorized_for?(:action => :move_lower)

      assert source3.authorized_for?(:action => :move_higher)
      assert !source3.authorized_for?(:action => :move_lower)

      assert source1.authorized_for?(:action => :anything_else)
    end

  end

end
