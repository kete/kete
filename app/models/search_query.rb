class SearchQuery

  # Responsibilities
  # * encapsulate the user's question to us (their search)
  # * be an opaque barrier between 
  #     1. HTML form & params hash
  #     2. rest of the system

  attr_reader :search_terms, 
              :date_since,
              :date_until,
              # :privacy_type,
              :content_item_type,
              # :topic_type,
              :basket,
              :page

  def initialize(params)

    # the string that the user typed into the search box
    @search_terms = params[:search_terms]

    # ?exactly what date in DB does this constrain?
    # ? wording in UI copy implies that user can enter a date and/or time here
    #   but no word on how the format of that should be?
    #  TODO: put better, more descriptive name on these dates
    #  * looking at the DB the only dates that seem to be there are the standard rails ones
    #  * some rows have date stuff in their extended_content but not sure how that is searched
    @date_since   = params[:date_since]
    @date_until   = params[:date_until]


    # ? what do these mean exactly?
    # possible values: "public"|"private"
    @privacy_type = params[:privacy_type]

    # * if present, this limits the search to just the named content-item-type
    # * there does not seem to be a way to selecte a subset of the
    #   content-item-types (it's either all or one)
    @content_item_type = params[:controller_name_for_zoom_class] || default_content_item_type

    # * a string representing the name of a topic type (an instance of TopicType)
    # * only sent in the form when params[:content_item_type] is also sent
    # * e.g. general, person, artist, place, event
    # * if this exists, then we are searching topics and we should limit our
    #   search to topics which have this topic-type
    @topic_type = params[:topic_type]

    # the name of the basket within which the search should happen
    @basket = params[:target_basket] || "site" #FIXME pull this from Basket

    # the page of results (within a content-type) that the user would like to see
    # * defaults to the first page
    # * params[:page] is set by the will_paginate gem
    @page = params[:page] || 1
  end


  def missing_search_terms?
    @search_terms.nil?
  end

  def pagination_link_params 
    to_hash
  end

  # def query_string_for(content_item_type)
  #   to_hash.map { |key, value| "#{key}=#{value}" }.join('&')
  # end

  def query_params_for(content_item_type)
    to_hash.merge({ controller_name_for_zoom_class: content_item_type })
  end

  def to_title
    "All results in #{content_item_type.pluralize.humanize} for "#{search_terms}" ...other query info here..."
  end

  private

  def to_hash
    {
      search_terms: search_terms,
      target_basket: basket,
      controller_name_for_zoom_class: content_item_type
    }
  end

  def default_content_item_type
    "Topic"
  end
end
