require File.dirname(__FILE__) + '/../test_helper'

# see search.rb comments at top
# not an ActiveRecord descendent
class SearchTest < Test::Unit::TestCase
  def setup
    # hash of params to use as the basis for tests
    # handling simple case first, all action
    # with no other params set
    @options = { :default => 'none',
      :query => String.new,
      :user_specified => nil,
      :direction => nil,
      :action => 'all',
      :search_terms => nil}

    @sort_stub = '@attr 7='
    @title_query = "@or #{@sort_stub}1 @attr 1=4 0 "
    @title_reverse_query = "@or #{@sort_stub}2 @attr 1=4 0 "
    @last_modified_query = "@or #{@sort_stub}2 @attr 1=1012 0 "
    @last_modified_reverse_query = "@or #{@sort_stub}1 @attr 1=1012 0 "
    @date_query = "@or #{@sort_stub}2 @attr 1=30 0 "
    @date_reverse_query = "@or #{@sort_stub}1 @attr 1=30 0 "
  end

  # add_sort_to_query_if_needed

  def test_boolean_operators
    assert_not_nil Search.boolean_operators
    assert Search.boolean_operators.is_a?(Array)
    assert_equal ['and', 'or', 'not'], Search.boolean_operators
  end

  def test_date_types
    assert_not_nil Search.date_types
    assert Search.date_types.is_a?(Array)
    assert_equal ['last_modified', 'date'], Search.date_types
  end

  def test_sort_types
    assert_not_nil Search.sort_types
    assert Search.sort_types.is_a?(Array)
    assert_equal ['title'] + Search.date_types, Search.sort_types
  end

  def test_sort_type_options_for_default_all
    result_string = '<option value="title">Title</option><option value="last_modified" selected="selected">Last modified</option><option value="date">Date</option>'
    assert_equal result_string, Search.new.sort_type_options_for(nil, 'all')
  end

  def test_sort_type_options_for_default_for
    result_string = '<option value="none">Relevance</option><option value="title">Title</option><option value="last_modified">Last modified</option><option value="date">Date</option>'
    assert_equal result_string, Search.new.sort_type_options_for(nil, 'for')
  end

  def test_sort_type_default_all_should_be_last_modified
    assert_equal 'last_modified', Search.new.sort_type(@options)
  end

  def test_sort_type_default_for_should_be_none
    options = @options.merge({ :search_terms => 'bob dobbs', :action => 'for' })
    assert_equal 'none', Search.new.sort_type(options)
  end

  def test_sort_type_default_rss_should_be_last_modified
    options = @options.merge({ :action => 'rss' })
    assert_equal 'last_modified', Search.new.sort_type(options)
  end

  def test_sort_type_rss_with_search_terms_should_be_last_modified
    options = @options.merge({ :search_terms => 'bob dobbs', :action => 'rss' })
    assert_equal 'last_modified', Search.new.sort_type(options)
  end

  def test_sort_type_all_with_user_specified
    Search.sort_types.each do |type|
      options = @options.merge({ :user_specified => type, :action => 'all' })
      assert_equal type, Search.new.sort_type(options)
    end
  end

  def test_sort_type_rss_always_last_modified
    options = @options.merge({ :user_specified => 'title', :action => 'rss' })
    assert_equal 'last_modified', Search.new.sort_type(options)
  end

  def test_sort_direction_pqf_with_nil_requested_and_title_sort_type
    assert_equal '@attr 7=1', Search.new.sort_direction_pqf(nil, 'title')
  end

  def test_sort_direction_pqf_with_nil_requested_and_date_type
    Search.date_types.each do |type|
      assert_equal '@attr 7=2',Search.new.sort_direction_pqf(nil, type)
    end
  end

  def test_sort_direction_pqf_with_reverse_requested_and_title_sort_type
    assert_equal '@attr 7=2',Search.new.sort_direction_pqf('reverse', 'title')
  end

  def test_sort_direction_pqf_with_rerverse_requested_and_date_type
    Search.date_types.each do |type|
      assert_equal '@attr 7=1',Search.new.sort_direction_pqf('reverse', type)
    end
  end

  # add_sort_to_query_if_needed tests
  # possible results

  # query (blank is expected from @options)
  def test_add_sort_to_query_if_needed_should_be_only_blank_query
    options = @options.merge({ :search_terms => 'bob dobbs', :action => 'for' })
    assert Search.new.add_sort_to_query_if_needed(options).blank?
  end

  # title and title reverse added to query
  def test_add_sort_to_query_if_needed_should_be_title_query
    options = @options.merge({ :user_specified => 'title', :action => 'all' })
    assert_equal @title_query, Search.new.add_sort_to_query_if_needed(options)
  end

  def test_add_sort_to_query_if_needed_should_be_title_reverse_query
    options = @options.merge({ :user_specified => 'title', :action => 'all', :direction => 'reverse' })
    assert_equal @title_reverse_query, Search.new.add_sort_to_query_if_needed(options)
  end

  # last_modified and last_modified reverse added to query
  def test_add_sort_to_query_if_needed_should_be_last_modified_query
    options = @options.merge({ :user_specified => 'last_modified', :action => 'all' })
    assert_equal @last_modified_query, Search.new.add_sort_to_query_if_needed(options)
  end

  def test_add_sort_to_query_if_needed_should_be_last_modified_reverse_query
    options = @options.merge({ :user_specified => 'last_modified', :action => 'all', :direction => 'reverse' })
    assert_equal @last_modified_reverse_query, Search.new.add_sort_to_query_if_needed(options)
  end

  # date and date reverse added to query
  def test_add_sort_to_query_if_needed_should_be_date_query
    options = @options.merge({ :user_specified => 'date', :action => 'all' })
    assert_equal @date_query, Search.new.add_sort_to_query_if_needed(options)
  end

  def test_add_sort_to_query_if_needed_should_be_date_reverse_query
    options = @options.merge({ :user_specified => 'date', :action => 'all', :direction => 'reverse' })
    assert_equal @date_reverse_query, Search.new.add_sort_to_query_if_needed(options)
  end

  # rss action should always be last_modified
  def test_add_sort_to_query_if_needed_should_always_be_last_modified_for_rss
    Search.sort_types.each do |type|
      options = @options.merge({ :user_specified => type, :action => 'rss' })
      assert_equal @last_modified_query, Search.new.add_sort_to_query_if_needed(options)
    end
  end

  def test_add_sort_to_query_if_needed_should_always_be_last_modified_for_rss_reverse
    Search.sort_types.each do |type|
      options = @options.merge({ :user_specified => type, :action => 'rss', :direction => 'reverse' })
      assert_equal @last_modified_reverse_query, Search.new.add_sort_to_query_if_needed(options)
    end
  end
end
