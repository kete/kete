require 'test_helper'

class SearchSourceTest < ActiveSupport::TestCase

  @@new_model = { :title => 'Test Search Source',
                  :source_type => 'feed',
                  :base_url => 'http://example.com/rss.xml?q=',
                  :more_link_base_url => 'http://example.com/?q=',
                  :limit => 5,
                  :cache_interval => 5,
                  :or_syntax => { :position => 'between', :case => 'upper' } }

  test "The Search Source model should contain a class var of acceptable source types" do
    assert_equal %w{ feed }, SearchSource.acceptable_source_types
  end

  test "The Search Source model should require that source_type be in SearchSource.acceptable_source_types" do
    source = SearchSource.new(@@new_model.merge(:source_type => 'invalid'))
    assert !source.valid?
    assert 'must be one of the following: feed', source.errors['source_type']
  end

  test "The Search Source model should require that base url be of protocol type http" do
    source = SearchSource.new(@@new_model.merge(:base_url => 'feed://example.com/rss.xml'))
    assert !source.valid?
    assert 'requires an http protocol', source.errors['source_type']
  end

  test "The Search Source model should have a method that returns a title based id for html element ids" do
    source = SearchSource.new(@@new_model)
    assert_equal 'test_search_source', source.title_id
  end

  test "The Search Source model should have an authorized_for? method that works with alongside ActiveScaffold" do
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

  test "The Search Source model should sort the sources by position by default" do
    source1 = SearchSource.create(@@new_model.merge(:position => 3))
    source2 = SearchSource.create(@@new_model.merge(:position => 1))
    source3 = SearchSource.create(@@new_model.merge(:position => 2))

    sources = SearchSource.all
    assert source2, sources[0]
    assert source3, sources[1]
    assert source1, sources[2]
  end

  test "The Search Source model should be configurable" do
    source = SearchSource.create(@@new_model)
    source.settings[:or_syntax] = { :position => 'between', :case => 'upper' }
    assert_equal({ :position => 'between', :case => 'upper' }, source.settings[:or_syntax])
  end

end
