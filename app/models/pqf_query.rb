# used for translating Kete search queries to
# PQF queries that our ZoomDb understands
class PqfQuery
  # relevance attribute spec says, in essence
  # sort by dynamic relevance ranking (based on query)
  # and match partial words (truncated on either the left or right, i.e. both)
  # and do fuzzy matching (any one character in term may be replaced to match in search)
  # i.e.
  # add the dynamic relevance ranking
  # allowing for incomplete search terms
  # and fuzzy (one misspelled character)
  # relevancee relies on our zoom dbs having it configured
  # kete zebra servers should be configured properly to use it
  # we may need to adjust when querying non-kete zoom_dbs (koha for example)
  # see comment above about current_basket
  # see #{RAILS_ROOT}zebradb/conf/cql2pqf.txt for details

  # PQF attribute specs based on
  # customized bib1 attribute set
  # found in #{RAILS_ROOT}zebradb/tab/bib1.att
  # see #{RAILS_ROOT}zebradb/conf/oai2index.xsl
  # for mappings of oai dc xml elements to specific indexes
  QUALIFYING_ATTRIBUTE_SPECS = {
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

  ATTRIBUTE_SPECS = {
    'oai_identifier' => "@attr 1=12 ",
    'oai_setspec' => "@attr 1=20 ",
    'relations' => "@attr 1=1026 ",
    'subjects' => "@attr 1=21 ",
    'creators' => "@attr 1=1003 ",
    'contributors' => "@attr 1=1020 ",
    'title' => "@attr 1=4 ",
    'any_text' => "@attr 1=1016 ",
    'last_modified' => "@attr 1=1012 #{QUALIFYING_ATTRIBUTE_SPECS['datetime']}",
    'date' => "@attr 1=30 #{QUALIFYING_ATTRIBUTE_SPECS['datetime']}",
    'last_modified_sort' => "@attr 1=1012 ",
    'date_sort' => "@attr 1=30 "
  }

  # TODO: my hash_fu is failing me, DRY this up
  DATETIME_SPECS = { 'oai_datestamp' => ATTRIBUTE_SPECS['last_modified'],
    'last_modified' => ATTRIBUTE_SPECS['last_modified'],
    'date' => ATTRIBUTE_SPECS['date']
  }

  DATETIME_COMPARISON_SPECS = { 'before' => QUALIFYING_ATTRIBUTE_SPECS['lt'],
    'after' => QUALIFYING_ATTRIBUTE_SPECS['gt'],
    'on' => QUALIFYING_ATTRIBUTE_SPECS['eq'],
    'on_or_before' => QUALIFYING_ATTRIBUTE_SPECS['le'],
    'on_or_after' => QUALIFYING_ATTRIBUTE_SPECS['ge']
  }

  # all ATTRIBUTE_SPECS wll have ..._include method created for them
  # except what is specified here
  # any spec with sort in its key is skipped
  DO_NOT_AUTO_DEF_INCLUDE_METHODS_FOR = ATTRIBUTE_SPECS.keys.select { |key| key.include?('sort') }

  attr_accessor :query_parts, :operators,
  :title_or_any_text_query_string, :title_or_any_text_operators_string,
  :direction_value, :sort_spec, :should_search_web_links_to

  # dynamically define query methods for our attribute specs
  def self.define_query_method_for(method_name, attribute_spec)
    # create the template code
    code = Proc.new { |term_or_terms, *options|
      options = options.first || Hash.new
      terms = terms_as_array(term_or_terms)

      # make default operator @and, if unspecified
      options[:operator] = options[:operator].nil? ? '@and' : options[:operator]
      # pass nil operator, if 'none' is specified
      options[:operator] = nil if options[:operator] == 'none'

      query_part = create_query_part(options.merge({ :attribute_spec => attribute_spec,
                                                     :term_or_terms => terms }))
    }

    define_method(method_name, &code)
  end

  def initialize
    @query_parts = Array.new
    @operators = Array.new
    @title_or_any_text_query_string = String.new
    @title_or_any_text_operators_string = String.new
    @direction_value = 1
    @sort_spec = nil
    @should_search_web_links_too = false
  end

  # combine query_parts and operators
  # add any special aspects to query if required
  # and spit out complete query as string
  # suitable to be passed to ZOOM::Connection#search
  def to_s
    # handle the query as specified in standard ways so far
    full_query = @operators.join(' ') + ' ' + @query_parts.join(' ') + ' '

    # add special handling of searching URLs within dc subject
    if @should_search_web_links_too
      full_query = '@or ' + full_query +
        ATTRIBUTE_SPECS['subjects'] +
        @title_or_any_text_operators_string +
        @title_or_any_text_query_string + ' '
    end

    # add sorting if specified
    if !@sort_spec.nil?
      # date specs when doing a non-sorting query
      # have a slightly different format (specifies structure of date normalized as @attr 4=5)
      # grab the correct spec for sorting
      @sort_spec = @sort_spec +
        '_sort' if Search.date_types.include?(@sort_spec) && !@sort_spec.include?('_sort')

      full_query = '@or ' + full_query + QUALIFYING_ATTRIBUTE_SPECS['sort_stub'] + @direction_value.to_s + ' ' + ATTRIBUTE_SPECS[@sort_spec] + ' 0 '
    end
    full_query
  end

  # dynamically define _include methods for our attribute specs
  ATTRIBUTE_SPECS.each do |spec_key, spec_value|
    unless DO_NOT_AUTO_DEF_INCLUDE_METHODS_FOR.include?(spec_key)
      method_name = spec_key + '_include'
      define_query_method_for(method_name, spec_value)
    end
  end

  # TODO: make this more concise via singleton method?
  # even if we only have a single term
  # make sure we always pass an array down to create_query_part
  def terms_as_array(terms)
    return terms if terms.is_a?(Array)
    terms = terms_to_a(terms)
  end

  def terms_to_a(*terms)
    terms
  end

  # we know that the format of oai_identifier is the following:
  # oai:site:basket:Class:id
  # if we want to search for an exact match for an element
  # we wrap the term likeso ":term:"
  def exact_match_for_part_of_oai_identifier(term_or_terms, *options)
    options = options.first || Hash.new

    terms = terms_as_array(term_or_terms).collect { |term| ":#{term.to_s}:" }

    oai_identifier_include(terms, options)
  end


  # expects term_or_terms to be strings that are in db normalized datetimes
  # can (and probably should) include utc offset
  # i.e. "1999-12-31 23:59:59+00:00"
  DATETIME_SPECS.each do |spec_key, spec_value|
    DATETIME_COMPARISON_SPECS.each do |comparison_name, comparison_spec|
      method_name = spec_key + '_' + comparison_name
      full_attribute = comparison_spec + spec_value

      define_query_method_for(method_name, full_attribute)
    end
  end

  def oai_datestamp_between(options = { })
    beginning = options[:beginning]
    ending = options[:ending]

    query_part = '@and ' + oai_datestamp_on_or_after(beginning,
                                                     options.merge({ :only_return_as_string => true,
                                                                     :operator => 'none'}))
    query_part += ' ' + oai_datestamp_on_or_before(ending,
                                                   options.merge({ :only_return_as_string => true,
                                                                   :operator => 'none'}))

    push_to_appropriate_variables(options.merge(:query_part => query_part)) unless options[:only_return_as_string]
    query_part
  end

  # a wrapper that sets up the correct query
  # depending on what options are specified
  def oai_datestamp_comparison(options = { })
    beginning = !options[:beginning].blank? ? options[:beginning] : nil
    ending = !options[:ending].blank? ? options[:ending] : nil

    if !beginning.nil? && !ending.nil?
      oai_datestamp_between(options)
    elsif !beginning.nil? && ending.nil?
      options.delete(:beginning)
      oai_datestamp_on_or_after(beginning, options)
    elsif !ending.nil? && beginning.nil?
      options.delete(:ending)
      oai_datestamp_on_or_before(ending, options)
    end
  end

  def creators_or_contributors_include(term_or_terms, options = { })
    query_part = '@or ' + creators_include(term_or_terms,
                                           options.merge({ :only_return_as_string => true,
                                                           :operator => 'none'}))
    query_part += ' ' + contributors_include(term_or_terms,
                                             options.merge({ :only_return_as_string => true,
                                                             :operator => 'none'}))

    push_to_appropriate_variables(options.merge(:query_part => query_part, :operator => '@and')) unless options[:only_return_as_string]
    query_part
  end

  # this is standard full text query
  # of entire record
  # by adding query for title first
  # we give matches against title
  # higher relevance
  # includes sorting by dynamic relevance
  # by default
  def title_or_any_text_includes(terms)
    query_part = QUALIFYING_ATTRIBUTE_SPECS['relevance']
    operator = '@and'
    terms = pqf_format(terms)

    title_query = '@or ' + ATTRIBUTE_SPECS['title'] + ' '
    all_content_query = ATTRIBUTE_SPECS['any_text'] + ' '

    if !terms.blank?
      if terms.size > 1

        # work through terms
        # if there is a boolean operator specified
        # add it to the correct spot
        # if not specified add another "@and"
        term_count = 1
        terms_array = Array.new
        operators_array = Array.new
        query_starts_with_not = false
        last_term_an_operator = false
        terms.each do |term|
          # if first term is boolean operator "not"
          # then replace the @and for this element of the query with @not
          # all other boolean operators are treated as normal words if first term
          if term_count == 1
            if term.downcase == 'not'
              query_starts_with_not = true
            else
              terms_array << term
            end
          else
            if term_count > 1
              # in the rare case that @not has replaced
              # @and at the front of the whole query
              # and this is the second term
              # skip adding a boolean operator
              if query_starts_with_not == true and term_count == 2
                # this just treats even terms found in
                # Search.boolean_operators as regular words
                # since their placement makes them meaningless as boolean operators
                terms_array << term
              else
                if Search.boolean_operators.include?(term)
                  # we got ourselves an operator
                  operators_array << "@#{term}"
                  last_term_an_operator = true
                else
                  # just a plain term
                  if last_term_an_operator == false
                    # need to add an operator
                    # assume "and" since none-specified
                    operators_array << "@and "
                  end

                  terms_array << term
                  last_term_an_operator = false
                end
              end
            end
          end

          term_count += 1
        end

        # handle case where the user has enterd two or more operators in a row
        # we just subtract one from the beginning of operators_array
        while operators_array.size >= terms_array.size
          operators_array.delete_at(0)
        end

        if operators_array.size > 0
          @title_or_any_text_operators_string = operators_array.join(" ") + " "

          title_query += @title_or_any_text_operators_string
          all_content_query += @title_or_any_text_operators_string
        end

        if query_starts_with_not == true
          operator += "@not"
        end

        @title_or_any_text_query_string = "\"" + terms_array.join("\" \"") + "\" "
        title_query += @title_or_any_text_query_string
        all_content_query += @title_or_any_text_query_string

        query_part += title_query + all_content_query
      else
        # @and will break query if only single term
        @title_or_any_text_query_string = "\"" + terms.join("\" \"") + "\" "
        query_part += "#{title_query} #{@title_or_any_text_query_string} #{all_content_query} #{@title_or_any_text_query_string} "
      end
    end
    push_to_appropriate_variables({:query_part => query_part, :operator => operator})
    query_part
  end

  def add_web_link_specific_query
    @should_search_web_links_too = true
  end

  # aliases for readability's sake
  alias :oai_datestamp_include :last_modified_include
  alias :kind_is :exact_match_for_part_of_oai_identifier
  alias :within :exact_match_for_part_of_oai_identifier

  private

  # quote each term to handle phrases, etc.
  def pqf_format(terms)
    # handles case were someone is searching for a url
    # there may be other special characters to handle
    # but this seems to do the trick
    terms = terms.gsub("/", "\/")

    # this is sort of cheating
    # we know that Topic class has the acts_as_zoom instance methods...
    terms = Topic.split_to_search_terms(terms)

    terms
  end

  def push_to_appropriate_variables(options = { })
    @operators << options[:operator] if !options[:operator].blank? && options[:operator] != 'none'
    @query_parts << options[:query_part] unless options[:only_return_as_string]
  end

  # expects single string for term_or_terms
  # or array of strings
  def create_query_part(options = { })
    query_part = options[:attribute_spec]
    # should always be an array by the time it gets here
    term_or_terms = options[:term_or_terms]
    should_be_exact = options[:should_be_exact] || false
    inner_operator = options[:inner_operator] || '@or'

    query_part += '@attr 4=3 ' if should_be_exact

    if term_or_terms.size == 1
      query_part += "\"#{term_or_terms}\""
    else
      # get the correct number of inner_operators
      # essentially the number of terms - 1
      # but we already have the first instance...
      operators_string = inner_operator
      number_of = term_or_terms.size - 2
      number_of.times do
        operators_string += " #{inner_operator}"
      end
      # we always quote since it won't hurt when they aren't needed
      query_part += "#{operators_string} \"" + term_or_terms.join("\" \"") + "\""
    end

    push_to_appropriate_variables(options.merge(:query_part => query_part))
    query_part
  end

end
