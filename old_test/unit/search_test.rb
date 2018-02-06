require File.dirname(__FILE__) + '/../test_helper'

# see search.rb comments at top
# not an ActiveRecord descendent
class SearchTest < ActiveSupport::TestCase
  def setup
    # hash of params to use as the basis for tests
    # handling simple case first, all action
    # with no other params set
    @options = { 
      :default => 'none',
      :query => String.new,
      :user_specified => nil,
      :direction => nil,
      :action => 'all',
      :search_terms => nil 
    }

    @sort_stub = '@attr 7='
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
    result_string = '<option class="title" value="title">Title</option><option class="last_modified" value="last_modified" selected="selected">Last Modified</option><option class="date" value="date">Date</option>'
    assert_equal result_string, Search.new.sort_type_options_for(nil, 'all')
  end

  def test_sort_type_options_for_default_for
    result_string = '<option class="none" value="none">Relevance</option><option class="title" value="title">Title</option><option class="last_modified" value="last_modified">Last Modified</option><option class="date" value="date">Date</option>'
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

  def self.define_tests_of_sort_direction_value
    Search.sort_types.each do |sort_type|
      method_name = "test_sort_direction_value_for_" + sort_type
      direction_value = Search.date_types.include?(sort_type) ? 2 : 1
      requested = nil

      code =
        Proc.new do
          @search = Search.new
               @search.update_sort_direction_value_for_pqf_query(requested, sort_type)
               assert_equal direction_value, @search.pqf_query.direction_value
        end

      define_method(method_name, &code)

      method_name += '_reverse'
      direction_value = Search.date_types.include?(sort_type) ? 1 : 2
      requested = 'reverse'

      define_method(method_name, &code)
    end
  end

  define_tests_of_sort_direction_value

  # rss action should always be last_modified
  def test_add_sort_to_query_if_needed_should_always_be_last_modified_for_rss
    Search.sort_types.each do |type|
      options = @options.merge({ :user_specified => type, :action => 'rss' })
      assert_equal "last_modified", Search.new.add_sort_to_query_if_needed(options)
    end
  end

  def test_add_sort_to_query_if_needed_should_always_be_last_modified_for_rss_reverse
    Search.sort_types.each do |type|
      options = @options.merge({ :user_specified => type, :action => 'rss', :direction => 'reverse' })
      assert_equal "last_modified", Search.new.add_sort_to_query_if_needed(options)
    end
  end

  def self.define_tests_of_add_sort_to_query_if_needed_should_be
    Search.sort_types.each do |sort_type|
      method_name = "test_add_sort_to_query_if_needed_should_be_" + sort_type

      local_options = { :user_specified => sort_type, :action => 'all' }

      define_method(method_name) do
        options = @options.merge(local_options)
        @search = Search.new
        @search.add_sort_to_query_if_needed(options)
        assert_equal sort_type, @search.pqf_query.sort_spec
      end

      method_name += '_reverse'
      local_options = local_options.merge({ :direction => 'reverse' })
      correct_reverse_sort_direction_value = Search.date_types.include?(sort_type) ? 1 : 2

      define_method(method_name) do
        options = @options.merge(local_options)
        @search = Search.new
        @search.add_sort_to_query_if_needed(options)
        assert_equal sort_type, @search.pqf_query.sort_spec
        assert_equal correct_reverse_sort_direction_value, @search.pqf_query.direction_value
      end
    end
  end

  define_tests_of_add_sort_to_query_if_needed_should_be

  #
  # Previous Search functionality
  #

  context "Previous search functionality" do
    setup do
      @search_options = { :title => 'Custom Search', :url => "http://something.com/#{rand}" }
      @user1 = create_new_user(:login => 'User1')
      @user2 = create_new_user(:login => 'User2')
      assert (@user1 != @user2)
    end

    should "belong to a user" do
      search = Search.create!(@search_options.merge(:user => @user1))
      assert_equal @user1, search.user
      assert @user1.searches.include?(search)
    end

    should "require user, title, and url be present" do
      search = Search.create
      ["User can't be blank", "Title can't be blank", "Url can't be blank"].each do |error|
        assert search.errors.full_messages.include?(error)
      end
    end

    should "require a unique url scoped to the current user" do
      search1 = Search.create(@search_options.merge(:user => @user1))
      assert search1.valid?

      search2 = Search.create(@search_options.merge(:user => @user1))
      assert !search2.valid?
      assert search2.errors.full_messages.include?('Url has already been taken')

      search3 = Search.create(@search_options.merge(:user => @user2))
      assert search3.valid?
    end

    should "sort searches from most recent to oldest, using date, then ID" do
      options = @search_options.merge(:user => @user1)

      search1 = Search.create(options.merge(:url => "http://something.com/#{rand}"))
      search2 = Search.create(options.merge(:url => "http://something.com/#{rand}"))
      search3 = Search.create(options.merge(:url => "http://something.com/#{rand}"))

      assert_equal [search3, search2, search1], @user1.searches.all
    end
  end
end
