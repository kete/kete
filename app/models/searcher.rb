class Searcher

  def initialize(query: SearchQuery.new)
    @query = query
  end

  def run
    result_docs = PgSearch.multisearch(query.search_terms)

    # => ActiveRecord::Relation
    # result_docs.first.searchable returns the real model that was found
    # binding.pry
    # need to filter down the results based on the criteria we got from query


    # return an array of SearchResult or []
    []
  end

  private

  attr_reader :query

end
