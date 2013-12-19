class Searcher

  def initialize(query: SearchQuery.new)
    @query = query
  end

  def run
    PgSearch.multisearch(query.search_terms) # => ActiveRecord::Relation

    # do any filtering down of results based on query parameters here
    # returns ActiveRecord::Relation
  end

  def all
    PgSearch::Document.where('1=1') 
    # returns ActiveRecord::Relation
  end

  private

  attr_reader :query

end
