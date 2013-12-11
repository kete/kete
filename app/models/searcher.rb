class Searcher

  # class SearchResult
  #   def initialize(paginitation_info, klass)

  #   def count_for(content_type) # => Fixnum

  #   def results_for(content_type) # => ActiveRecord::Relation
  #     # pagination happens in here
  #     # we do not return a relation
  #   end

  #   
  # end

  def initialize(query: SearchQuery.new)
    @query = query
  end

  def run
    PgSearch.multisearch(query.search_terms)
    # do any filtering down of results based on query parameters here



    # must return ActiveRecord::Relation
  end

  private

  attr_reader :query

end
