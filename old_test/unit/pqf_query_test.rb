# frozen_string_literal: true

require File.dirname(__FILE__) + '/../test_helper'

class PqfQueryTest < ActiveSupport::TestCase
  def setup
    @pqf_query = PqfQuery.new

    # Rather than type out constant names each time
    # we assign shorter instance variables
    @qas = PqfQuery::QUALIFYING_ATTRIBUTE_SPECS
    @as = PqfQuery::ATTRIBUTE_SPECS
    @dts = PqfQuery::DATETIME_SPECS
    @dtcs = PqfQuery::DATETIME_COMPARISON_SPECS
    @dnadimf = PqfQuery::DO_NOT_AUTO_DEF_INCLUDE_METHODS_FOR
  end

  def test_constants_are_defined
    # Check all the constants are being defined because we use them later
    assert_equal "constant", defined?(PqfQuery::QUALIFYING_ATTRIBUTE_SPECS)
    assert_equal "constant", defined?(PqfQuery::ATTRIBUTE_SPECS)
    assert_equal "constant", defined?(PqfQuery::DATETIME_SPECS)
    assert_equal "constant", defined?(PqfQuery::DATETIME_COMPARISON_SPECS)
    assert_equal "constant", defined?(PqfQuery::DO_NOT_AUTO_DEF_INCLUDE_METHODS_FOR)
  end

  def test_constants_have_right_data
    # The constants in PqfQuery class pull values from other constants defined before them
    # We subsitute those values with what it should be, and check that its working as expected

    qualifying_attribute_specs = {
      'relevance' => "@attr 2=102 @attr 5=3 ",
      'exact' => "@attr 4=3 ",
      'complete' => "@attr 6=3 ",
      'partial' => "@attr 5=3 ",
      'fuzzy_regexp' => "@attr 5=103 ",
      'datetime' => "@attr 4=5 ",
      'exact_url' => "@attr 4=104 ",
      'lt' => "@attr 2=1 ",
      'le' => "@attr 2=2 ",
      'eq' => "@attr 2=3 ",
      'ge' => "@attr 2=4 ",
      'gt' => "@attr 2=5 ",
      'sort_stub' => "@attr 7="
    }
    assert_equal qualifying_attribute_specs, @qas

    attribute_specs = {
      'oai_identifier' => "@attr 1=12 ",
      'oai_setspec' => "@attr 1=20 ",
      'description' => "@attr 1=1010 ",
      'relations' => "@attr 1=1026 ",
      'subjects' => "@attr 1=21 ",
      'creators' => "@attr 1=1003 ",
      'contributors' => "@attr 1=1020 ",
      'title' => "@attr 1=4 ",
      'coverage' => "@attr 1=29 ",
      'any_text' => "@attr 1=1016 ",
      'last_modified' => "@attr 1=1012 @attr 4=5 ",
      'date' => "@attr 1=30 @attr 4=5 ",
      'last_modified_sort' => "@attr 1=1012 ",
      'date_sort' => "@attr 1=30 "
    }
    assert_equal attribute_specs, @as

    datetime_specs = {
      'oai_datestamp' => "@attr 1=1012 @attr 4=5 ",
      'last_modified' => "@attr 1=1012 @attr 4=5 ",
      'date' => "@attr 1=30 @attr 4=5 "
    }
    assert_equal datetime_specs, @dts

    datetime_comparison_specs = {
      'before' => "@attr 2=1 ",
      'after' => "@attr 2=5 ",
      'on' => "@attr 2=3 ",
      'on_or_before' => "@attr 2=2 ",
      'on_or_after' => "@attr 2=4 "
    }
    assert_equal datetime_comparison_specs, @dtcs

    do_not_auto_def_include_methods_for = ["last_modified_sort", "date_sort"]
    assert_equal do_not_auto_def_include_methods_for, @dnadimf
  end

  def test_to_string_and_add_web_link_specific_query
    assert_equal "  ", @pqf_query.to_s
    @pqf_query.add_web_link_specific_query # is another test on its own that the method successfully sets a class variable
    assert_equal "  @or @or #{@as['title']}#{@qas['exact_url']} #{@as['subjects']} ", @pqf_query.to_s # not sure why extra space comes up, but not a big deal
  end

  def test_correct_attribute_spec_methods_defined
    # There is some Ruby meta programming that sets up methods in a loop on execution
    # We check that those methods are infact defined at this point in the test
    assert_equal "method", defined?(@pqf_query.oai_identifier_include)
    assert_equal "method", defined?(@pqf_query.oai_setspec_include)
    assert_equal "method", defined?(@pqf_query.relations_include)
    assert_equal "method", defined?(@pqf_query.subjects_include)
    assert_equal "method", defined?(@pqf_query.creators_include)
    assert_equal "method", defined?(@pqf_query.contributors_include)
    assert_equal "method", defined?(@pqf_query.title_include)
    assert_equal "method", defined?(@pqf_query.any_text_include)
    assert_equal "method", defined?(@pqf_query.last_modified_include)
    assert_equal "method", defined?(@pqf_query.date_include)

    assert_equal "method", defined?(@pqf_query.oai_identifier_equals_completely)
    assert_equal "method", defined?(@pqf_query.oai_setspec_equals_completely)
    assert_equal "method", defined?(@pqf_query.relations_equals_completely)
    assert_equal "method", defined?(@pqf_query.subjects_equals_completely)
    assert_equal "method", defined?(@pqf_query.creators_equals_completely)
    assert_equal "method", defined?(@pqf_query.contributors_equals_completely)
    assert_equal "method", defined?(@pqf_query.title_equals_completely)
    assert_equal "method", defined?(@pqf_query.any_text_equals_completely)
    assert_equal "method", defined?(@pqf_query.last_modified_equals_completely)
    assert_equal "method", defined?(@pqf_query.date_equals_completely)

    assert_equal nil, defined?(@pqf_query.last_modified_sort_include)
    assert_equal nil, defined?(@pqf_query.date_sort_include)
  end

  def test_convert_terms_to_array
    # Check to make sure that what we pass in always comes back as an array
    assert_equal ['a', 'b', 'c'], @pqf_query.terms_as_array(['a', 'b', 'c'])
    assert_equal ['a', 'b', 'c'], @pqf_query.terms_to_a('a', 'b', 'c')
    assert_equal ['a'], @pqf_query.terms_as_array('a')
    assert_equal ['a b'], @pqf_query.terms_as_array('a b')
  end

  def test_exact_match_for_part_of_oai_identifier
    assert_equal "#{@as['oai_identifier']}#{@qas['partial']}\":Topic:\"", @pqf_query.exact_match_for_part_of_oai_identifier("topics".classify, :operator => 'none')
    assert_equal "#{@as['oai_identifier']}#{@qas['partial']}\":site:\"", @pqf_query.exact_match_for_part_of_oai_identifier(Basket.first.urlified_name)
    assert_equal "#{@as['oai_identifier']}#{@qas['partial']}@or \":site:\" \":documentation:\"", @pqf_query.exact_match_for_part_of_oai_identifier([Basket.first.urlified_name, Basket.last.urlified_name])
  end

  def test_datetime_spec_methods_defined
    # There is some Ruby meta programming that sets up methods in a loop on execution
    # We check that those methods are infact defined at this point in the test
    assert_equal "method", defined?(@pqf_query.oai_datestamp_before)
    assert_equal "method", defined?(@pqf_query.oai_datestamp_after)
    assert_equal "method", defined?(@pqf_query.oai_datestamp_on)
    assert_equal "method", defined?(@pqf_query.oai_datestamp_on_or_before)
    assert_equal "method", defined?(@pqf_query.oai_datestamp_on_or_after)
    assert_equal "method", defined?(@pqf_query.last_modified_before)
    assert_equal "method", defined?(@pqf_query.last_modified_after)
    assert_equal "method", defined?(@pqf_query.last_modified_on)
    assert_equal "method", defined?(@pqf_query.last_modified_on_or_before)
    assert_equal "method", defined?(@pqf_query.last_modified_on_or_after)
    assert_equal "method", defined?(@pqf_query.date_before)
    assert_equal "method", defined?(@pqf_query.date_after)
    assert_equal "method", defined?(@pqf_query.date_on)
    assert_equal "method", defined?(@pqf_query.date_on_or_before)
    assert_equal "method", defined?(@pqf_query.date_on_or_after)
  end

  def test_oai_datestamp_between
    # Check we get the right result for searching between two dates
    assert_equal "@and #{@dtcs['on_or_after']}#{@dts['oai_datestamp']}\"2008-01-01 00:00:00\" #{@dtcs['on_or_before']}#{@dts['oai_datestamp']}\"2008-12-31 23:59:59\"", @pqf_query.oai_datestamp_between({ :beginning => '2008-01-01 00:00:00', :ending => '2008-12-31 23:59:59', :only_return_as_string => true })
  end

  def test_oai_datestamp_comparison
    # Check we get the right result for between two dates, after date, and before date searches
    assert_equal "@and #{@dtcs['on_or_after']}#{@dts['oai_datestamp']}\"2008-01-01 00:00:00\" #{@dtcs['on_or_before']}#{@dts['oai_datestamp']}\"2008-12-31 23:59:59\"", @pqf_query.oai_datestamp_comparison({ :beginning => '2008-01-01 00:00:00', :ending => '2008-12-31 23:59:59', :only_return_as_string => true })
    assert_equal "#{@dtcs['on_or_after']}#{@dts['oai_datestamp']}\"2008-01-01 00:00:00\"", @pqf_query.oai_datestamp_comparison({ :beginning => '2008-01-01 00:00:00', :only_return_as_string => true })
    assert_equal "#{@dtcs['on_or_before']}#{@dts['oai_datestamp']}\"2008-12-31 23:59:59\"", @pqf_query.oai_datestamp_comparison({ :ending => '2008-12-31 23:59:59', :only_return_as_string => true })
  end

  def test_creators_or_contributors_include
    # Check we get the right result for searching by creator or contributors of name 'admin'
    assert_equal "@or #{@as['creators']}#{@qas['partial']}\"admin\" #{@as['contributors']}#{@qas['partial']}\"admin\"", @pqf_query.creators_or_contributors_include("admin", { :only_return_as_string => true })
  end

  def test_creators_or_contributors_equals_completely
    # Check we get the right result for searching by creator or contributors of name 'admin'
    assert_equal "@or #{@as['creators']}#{@qas['complete']}\"admin\" #{@as['contributors']}#{@qas['complete']}\"admin\"", @pqf_query.creators_or_contributors_equals_completely("admin", { :only_return_as_string => true })
  end

  def test_title_or_any_text_includes
    # Check we get the right result for searchin for a string in title or any_text
    assert_equal (@qas['relevance']).to_s, @pqf_query.title_or_any_text_includes("")
    assert_equal "#{@qas['relevance']}@or #{@as['title']}  \"One\"  #{@as['any_text']}  \"One\"  ", @pqf_query.title_or_any_text_includes("One")
    assert_equal "#{@qas['relevance']}@or #{@as['title']} @and  \"One\" \"Two\" #{@as['any_text']} @and  \"One\" \"Two\" ", @pqf_query.title_or_any_text_includes("One Two")
  end

  def test_methods_should_have_aliases
    # Check we get the right result when using method aliases
    assert_equal "#{@as['oai_identifier']}#{@qas['partial']}\":Topic:\"", @pqf_query.kind_is("topics".classify, :operator => 'none')
    assert_equal "#{@as['oai_identifier']}#{@qas['partial']}\":site:\"", @pqf_query.within(Basket.first.urlified_name)
  end

  def test_push_to_appropriate_variables
    # Check that values passed in are concatenated and accessable via to_S
    @pqf_query.title_or_any_text_includes("One Two")
    @pqf_query.oai_datestamp_comparison({ :beginning => '2008-01-01 00:00:00', :ending => '2008-12-31 23:59:59' })
    @pqf_query.creators_or_contributors_include("admin")
    expect = "@and @and #{@qas['relevance']}@or #{@as['title']} @and  \"One\" \"Two\" #{@as['any_text']} @and  \"One\" \"Two\"  @and #{@dtcs['on_or_after']}#{@dts['oai_datestamp']}\"2008-01-01 00:00:00\" #{@dtcs['on_or_before']}#{@dts['oai_datestamp']}\"2008-12-31 23:59:59\" @or #{@as['creators']}#{@qas['partial']}\"admin\" #{@as['contributors']}#{@qas['partial']}\"admin\" "
    assert_equal expect, @pqf_query.to_s
  end
end
