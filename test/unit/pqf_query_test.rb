require File.dirname(__FILE__) + '/../test_helper'

class PqfQueryTest < ActiveSupport::TestCase

  def setup
    @pqf_query = PqfQuery.new
  end

  def test_constants_are_defined
    assert_equal "constant", defined?(PqfQuery::QUALIFYING_ATTRIBUTE_SPECS)
    assert_equal "constant", defined?(PqfQuery::ATTRIBUTE_SPECS)
    assert_equal "constant", defined?(PqfQuery::DATETIME_SPECS)
    assert_equal "constant", defined?(PqfQuery::DATETIME_COMPARISON_SPECS)
    assert_equal "constant", defined?(PqfQuery::DO_NOT_AUTO_DEF_INCLUDE_METHODS_FOR)
  end

  def test_constants_have_right_data
    qualifying_attribute_specs = {
      'relevance' => "@attr 2=102 @attr 5=3 @attr 5=103 ",
      'exact' => "@attr 4=3 ",
      'datetime' => "@attr 4=5 ",
      'lt' => "@attr 2=1 ",
      'le' => "@attr 2=2 ",
      'eq' => "@attr 2=3 ",
      'ge' => "@attr 2=4 ",
      'gt' => "@attr 2=5 ",
      'sort_stub' => "@attr 7="
    }
    assert_equal qualifying_attribute_specs, PqfQuery::QUALIFYING_ATTRIBUTE_SPECS

    attribute_specs = {
      'oai_identifier' => "@attr 1=12 ",
      'oai_setspec' => "@attr 1=20 ",
      'relations' => "@attr 1=1026 ",
      'subjects' => "@attr 1=21 ",
      'creators' => "@attr 1=1003 ",
      'contributors' => "@attr 1=1020 ",
      'title' => "@attr 1=4 ",
      'any_text' => "@attr 1=1016 ",
      'last_modified' => "@attr 1=1012 @attr 4=5 ",
      'date' => "@attr 1=30 @attr 4=5 ",
      'last_modified_sort' => "@attr 1=1012 ",
      'date_sort' => "@attr 1=30 "
    }
    assert_equal attribute_specs, PqfQuery::ATTRIBUTE_SPECS

    datetime_specs = {
      'oai_datestamp' => "@attr 1=1012 @attr 4=5 ",
      'last_modified' => "@attr 1=1012 @attr 4=5 ",
      'date' => "@attr 1=30 @attr 4=5 "
    }
    assert_equal datetime_specs, PqfQuery::DATETIME_SPECS

    datetime_comparison_specs = {
      'before' => "@attr 2=1 ",
      'after' => "@attr 2=5 ",
      'on' => "@attr 2=3 ",
      'on_or_before' => "@attr 2=2 ",
      'on_or_after' => "@attr 2=4 "
    }
    assert_equal datetime_comparison_specs, PqfQuery::DATETIME_COMPARISON_SPECS

    do_not_auto_def_include_methods_for = ["date_sort", "last_modified_sort"]
    assert_equal do_not_auto_def_include_methods_for, PqfQuery::DO_NOT_AUTO_DEF_INCLUDE_METHODS_FOR
  end

  def test_to_string_and_add_web_link_specific_query
    assert_equal "  ", @pqf_query.to_s
    @pqf_query.add_web_link_specific_query
    assert_equal "@or   @attr 1=21  ", @pqf_query.to_s
  end

  def test_correct_attribute_spec_methods_defined
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
    assert_equal nil, defined?(@pqf_query.last_modified_sort_include)
    assert_equal nil, defined?(@pqf_query.date_sort_include)
  end

  def test_convert_terms_to_array
    assert_equal ['a', 'b', 'c'], @pqf_query.terms_as_array(['a', 'b', 'c'])
    assert_equal ['a', 'b', 'c'], @pqf_query.terms_to_a('a', 'b', 'c')
  end

  def test_exact_match_for_part_of_oai_identifier
    assert_equal "@attr 1=12 \":Topic:\"", @pqf_query.exact_match_for_part_of_oai_identifier("topics".classify, :operator => 'none')
    assert_equal "@attr 1=12 \":site:\"", @pqf_query.exact_match_for_part_of_oai_identifier(Basket.first.urlified_name)
    assert_equal "@attr 1=12 @or \":site:\" \":documentation:\"", @pqf_query.exact_match_for_part_of_oai_identifier([Basket.first.urlified_name, Basket.last.urlified_name])
  end

  def test_datetime_spec_methods_defined
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
    assert_equal "@and @attr 2=4 @attr 1=1012 @attr 4=5 \"2008-01-01 00:00:00\" @attr 2=2 @attr 1=1012 @attr 4=5 \"2008-12-31 23:59:59\"", @pqf_query.oai_datestamp_between({:beginning => '2008-01-01 00:00:00', :ending => '2008-12-31 23:59:59', :only_return_as_string => true})
  end

  def test_oai_datestamp_comparison
    assert_equal "@and @attr 2=4 @attr 1=1012 @attr 4=5 \"2008-01-01 00:00:00\" @attr 2=2 @attr 1=1012 @attr 4=5 \"2008-12-31 23:59:59\"", @pqf_query.oai_datestamp_comparison({:beginning => '2008-01-01 00:00:00', :ending => '2008-12-31 23:59:59', :only_return_as_string => true})
    assert_equal "@attr 2=4 @attr 1=1012 @attr 4=5 \"2008-01-01 00:00:00\"", @pqf_query.oai_datestamp_comparison({:beginning => '2008-01-01 00:00:00', :only_return_as_string => true})
    assert_equal "@attr 2=2 @attr 1=1012 @attr 4=5 \"2008-12-31 23:59:59\"", @pqf_query.oai_datestamp_comparison({:ending => '2008-12-31 23:59:59', :only_return_as_string => true})
  end

  def test_creators_or_contributors_include
    assert_equal "@or @attr 1=1003 \"admin\" @attr 1=1020 \"admin\"", @pqf_query.creators_or_contributors_include("admin", {:only_return_as_string => true})
  end

  def test_title_or_any_text_includes
    assert_equal "@attr 2=102 @attr 5=3 @attr 5=103 ", @pqf_query.title_or_any_text_includes("")
    assert_equal "@attr 2=102 @attr 5=3 @attr 5=103 @or @attr 1=4   \"One\"  @attr 1=1016   \"One\"  ", @pqf_query.title_or_any_text_includes("One")
    assert_equal "@attr 2=102 @attr 5=3 @attr 5=103 @or @attr 1=4  @and  \"One\" \"Two\" @attr 1=1016  @and  \"One\" \"Two\" ", @pqf_query.title_or_any_text_includes("One Two")
  end

  def test_methods_should_have_aliases
    assert_equal "@attr 1=12 \":Topic:\"", @pqf_query.kind_is("topics".classify, :operator => 'none')
    assert_equal "@attr 1=12 \":site:\"", @pqf_query.within(Basket.first.urlified_name)
  end

  def test_push_to_appropriate_variables
    @pqf_query.title_or_any_text_includes("One Two")
    @pqf_query.oai_datestamp_comparison({:beginning => '2008-01-01 00:00:00', :ending => '2008-12-31 23:59:59'})
    @pqf_query.creators_or_contributors_include("admin")
    expect = "@and @and @attr 2=102 @attr 5=3 @attr 5=103 @or @attr 1=4  @and  \"One\" \"Two\" @attr 1=1016  @and  \"One\" \"Two\"  @and @attr 2=4 @attr 1=1012 @attr 4=5 \"2008-01-01 00:00:00\" @attr 2=2 @attr 1=1012 @attr 4=5 \"2008-12-31 23:59:59\" @or @attr 1=1003 \"admin\" @attr 1=1020 \"admin\" "
    assert_equal expect, @pqf_query.to_s
  end
end
