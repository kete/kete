class Searcher

  def initialize(query: SearchQuery.new)
    @query = query
  end

  def run
    WillPaginate.per_page = 10
    # current_page = query.params[:page] || 1
    current_page = 1

    pg_search_docs = PgSearch.multisearch(query.search_terms).paginate(page: current_page) # => ActiveRecord::Relation

    # results = pg_search_docs.map do |doc|
    #   doc.searchable
    # end

    # content_item_types.each do |ci_type|
    #   result_stats[ci_type] = pg_search_docs.where(searchable_type: ci_type).count
    # end
    # binding.pry

    # results
    pg_search_docs
  end

  private

  attr_reader :query

end
