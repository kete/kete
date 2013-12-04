class SearchQuery

  attr_reader :search_terms

  def initialize(params)
      @search_terms = params[:search_terms]
      @date_since   = params[:date_since]
      @date_until   = params[:date_until]
      @privacy_type = params[:privacy_type]
      @topics       = params[:controller_name_for_zoom_class]
      @topic_type   = params[:topic_type]
      @basket       = params[:target_basket]
  end
end
