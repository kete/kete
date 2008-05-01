# Search class isn't an ActiveRecord descendent
# refactoring to make search_controller stuff move to search model
# has only just started, so this is limited
class Search
  def self.boolean_operators
    ['and', 'or', 'not']
  end

  def self.date_types
    ['last_modified', 'date']
  end

  def self.sort_types
    ['title'] + date_types
  end

  def sort_type_options_for(sort_type, action)
    with_relevance = action == 'for' ? true : false

    sort_type = sort_type(:action => action, :user_specified => sort_type, :default => 'none')

    sort_type_options = String.new
    full_sort_types = with_relevance ? ['relevance'] + Search.sort_types : Search.sort_types

    full_sort_types.each do |type|
      if type == 'relevance'
        sort_type_options += "<option value=\"none\""
      else
        sort_type_options += "<option value=\"#{type}\""
      end
      sort_type_options += " selected=\"selected\"" if !sort_type.nil? && type == sort_type
      sort_type_options += ">" + type.humanize + "</option>"
    end
    sort_type_options
  end

  def sort_type(options = { })
    sort_type = options[:user_specified] || options[:default]

    # if this is an "all" search
    # sort by date last modified, i.e. oai_datestamp
    # if this rss, we want last_modified to be taken into account
    sort_type = 'last_modified' if options[:action] == 'rss' || (sort_type == 'none' && (options[:search_terms].nil? && options[:action] == 'all'))

    sort_type
  end

  def sort_direction_pqf(requested, sort_type)
    pqf_stub = '@attr 7='
    direction_value = 1

    date_types = Search.date_types

    direction_value = 2 if (date_types.include?(sort_type) && (requested.nil? || requested != 'reverse')) || (!date_types.include?(sort_type) && !requested.nil? && requested == 'reverse')

    pqf_stub + direction_value.to_s
  end

  def add_sort_to_query_if_needed(options = { })
    query = options[:query]
    sort_type = sort_type(:default => 'none',
                          :user_specified => options[:user_specified],
                          :action => options[:action],
                          :search_terms => options[:search_terms])

    return query if sort_type == 'none'

    query += sort_direction_pqf(options[:direction], sort_type) + " "

    case sort_type
    when 'last_modified'
      query += "@attr 1=1012 0 "
    when 'title'
      query += "@attr 1=4 0 "
    when 'date'
      query += "@attr 1=30 0 "
    end

    query = "@or " + query
  end
end
