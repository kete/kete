require 'test_helper'

class FeedEntry
  attr_accessor :media_thumbnail, :enclosure
  def initialize(fake_data = nil)
    @media_thumbnail = fake_data
    @enclosure = fake_data
  end
end

class SearchSourceTest < ActiveSupport::TestCase

  @@new_model = { :title => 'Test Search Source',
                  :source_type => 'feed',
                  :source_target => 'homepage',
                  :base_url => 'http://example.com/rss.xml?q=',
                  :more_link_base_url => 'http://example.com/?q=',
                  :limit => 5,
                  :limit_param => 'limit',
                  :cache_interval => 5,
                  :or_syntax => { :position => 'between', :case => 'upper' } }

  test "The Search Source model should require that title and source type are present" do
    source = SearchSource.new(@@new_model.merge(:title => nil, :source_type => nil))
    assert !source.valid?
    assert_equal 'can\'t be blank', source.errors['title']
    assert_equal 'can\'t be blank', source.errors['source_type'][0]
  end

  test "The Search Source model should require that base url be of protocol type http" do
    source = SearchSource.new(@@new_model.merge(:base_url => 'feed://example.com/rss.xml'))
    assert !source.valid?
    assert_equal 'requires an http protocol', source.errors['base_url']
  end

  test "The Search Source model should require limit be either blank or an integer" do
    source1 = SearchSource.new(@@new_model.merge(:limit => 'string'))
    assert !source1.valid?
    assert_equal 'is not a number', source1.errors['limit']

    source2 = SearchSource.new(@@new_model.merge(:limit => nil))
    assert source2.valid?

    source3 = SearchSource.new(@@new_model.merge(:limit => 2))
    assert source3.valid?
  end

  test "The Search Source model should require cache interval be either blank or an integer" do
    source1 = SearchSource.new(@@new_model.merge(:cache_interval => 'string'))
    assert !source1.valid?
    assert_equal 'is not a number', source1.errors['cache_interval']

    source2 = SearchSource.new(@@new_model.merge(:cache_interval => nil))
    assert source2.valid?

    source3 = SearchSource.new(@@new_model.merge(:cache_interval => 2))
    assert source3.valid?
  end

  test "The Search Source model should contain a class var of acceptable source types" do
    assert_equal %w{ feed }, SearchSource.acceptable_source_types
  end

  test "The Search Source model should require that source_type be in SearchSource.acceptable_source_types" do
    source = SearchSource.new(@@new_model.merge(:source_type => 'invalid'))
    assert !source.valid?
    assert_equal 'must be one of the following: feed', source.errors['source_type']
  end

  test "The Search Source model should contain a class var of acceptable source targets" do
    assert_equal %w{ search homepage }, SearchSource.acceptable_source_targets
  end

  test "The Search Source model should require that source_target be in SearchSource.acceptable_source_targets" do
    source = SearchSource.new(@@new_model.merge(:source_target => 'invalid'))
    assert !source.valid?
    assert_equal 'must be one of the following: search, homepage', source.errors['source_target']
  end

  test "The Search Source model should contain a class var of acceptable limit params" do
    assert_equal %w{ limit num_results count }, SearchSource.acceptable_limit_params
  end

  test "The Search Source model should require that limit_param be in SearchSource.acceptable_limit_params or blank" do
    source = SearchSource.new(@@new_model.merge(:limit_param => 'invalid'))
    assert !source.valid?
    assert_equal 'must be one of the following: limit, num_results, count', source.errors['limit_param']

    source = SearchSource.new(@@new_model.merge(:limit_param => nil))
    assert source.valid?
  end

  test "The Search Source model should sort the sources by position by default" do
    source1 = SearchSource.create(@@new_model)
    source2 = SearchSource.create(@@new_model)
    source3 = SearchSource.create(@@new_model)
    source3.move_to_top

    sources = SearchSource.all
    assert_equal source3, sources[0]
    assert_equal source1, sources[1]
    assert_equal source2, sources[2]
  end

  test "The Search Source model should be configurable" do
    source = SearchSource.create(@@new_model)
    assert source.settings.is_a?(Array)
  end

  test "The Search Source model should set limit if it is blank, otherwise leave it" do
    source1 = SearchSource.create(@@new_model.merge(:limit => 10))
    assert_equal 10, source1.limit

    source2 = SearchSource.create(@@new_model.merge(:limit => nil))
    assert_equal 5, source2.limit
  end

  test "The Search Source model should set cache interval if it is blank, otherwise leave it" do
    source1 = SearchSource.create(@@new_model.merge(:cache_interval => 10))
    assert_equal 10, source1.cache_interval

    source2 = SearchSource.create(@@new_model.merge(:cache_interval => nil))
    assert_equal 1440, source2.cache_interval
  end

  test "The Search Source model should have an or_syntax getter method that gets its value from settings" do
    source = SearchSource.create(@@new_model)
    value = { :position => 'between', :case => 'upper' }
    source.settings[:or_syntax] = value
    assert_equal value, source.or_syntax
  end

  test "The Search Source model should have an or_syntax setter method that stores the value in an instance var" do
    value = { :position => 'between', :case => 'upper' }
    source = SearchSource.new(@@new_model.merge(:or_syntax => value))
    assert_equal value, source.or_syntax
  end

  test "The Search Source model should set or_syntax setting on search source save" do
    value = { :position => 'between', :case => 'upper' }
    source = SearchSource.create(@@new_model.merge(:or_syntax => value))
    assert_equal value, source.settings[:or_syntax]
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

  test "The Search Source model should correctly format search test with or syntax and escape" do
    source = SearchSource.create(@@new_model)

    source.or_syntax = { :position => 'between', :case => 'upper' }
    assert_equal 'this%20OR%20that', source.send(:parse_search_text, 'this that')

    source.or_syntax = { :position => 'between', :case => 'lower' }
    assert_equal 'this%20or%20that', source.send(:parse_search_text, 'this that')

    source.or_syntax = { :position => 'before', :case => 'upper' }
    assert_equal 'OR%20this%20that', source.send(:parse_search_text, 'this that')

    source.or_syntax = { :position => 'after', :case => 'upper' }
    assert_equal 'this%20that%20OR', source.send(:parse_search_text, 'this that')

    source.or_syntax = { :position => 'nothing', :case => 'upper' }
    assert_equal 'this%20that', source.send(:parse_search_text, 'this that')
  end

  test "Source url and more links aren't available until a feed is fetched" do
    source = SearchSource.create(@@new_model)
    assert_equal 'Source has not been fetched from yet.', source.source_url
    assert_equal 'Source has not been fetched from yet.', source.more_link
  end

  test "Source url and more links return expected url formats" do
    source = SearchSource.create(@@new_model)
    source.instance_eval { @search_text = 'test' }
    assert_equal 'http://example.com/rss.xml?q=test', source.source_url
    assert_equal 'http://example.com/?q=test', source.more_link
  end

  test "Sort entries returns a hash with expected values" do
    source = SearchSource.create(@@new_model)
    a,b,c,d = FeedEntry.new('1'), FeedEntry.new, FeedEntry.new('1'), FeedEntry.new
    expected = { :total => 4, :links => [b,d], :images => [a,c] }
    assert_equal expected, source.send(:sort_entries, [a,b,c,d])
  end

end
