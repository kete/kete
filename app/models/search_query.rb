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
              :basket_name,
              :page,
              :controller,
              :action,
              :tag,
              :related_item_id,
              :related_item_type,
              :user_id

  def initialize(params)
    @controller = params[:controller]
    @action = params[:action]

    # the string that the user typed into the search box
    @search_terms = "#{params[:search_terms]} #{params[:advanced_search_terms]}"

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
    @basket_name = params[:urlified_name] || 'site'

    # the page of results (within a content-type) that the user would like to see
    # * defaults to the first page
    # * params[:page] is set by the will_paginate gem
    @page = params[:page] || 1

    @tag = params[:tag]

    @related_item_id = params[:related_item_id]
    @related_item_type = params[:related_item_type]

    @user_id = params[:user_id]
  end

  def missing_search_terms?
    @search_terms.blank?
  end

  def pagination_link_params
    to_hash
  end

  def query_params_for(content_item_type)
    to_hash.merge({ controller_name_for_zoom_class: content_item_type })
  end

  def to_title
    "All results in #{content_item_type.pluralize.humanize} for '#{search_terms}' ...other query info here..."
  end

  def related_item_topic_query?
    @action == 'related_to' && related_item_type == 'Topic'
  end

  def searched_topic_id
    # Give the topic's id if items related to that topic where searched for.
    if related_item_topic_query?
      related_item_id
    else
      nil
    end
  end

  private

  def to_hash
    hash = {
      # target_basket: basket_name,
      controller_name_for_zoom_class: content_item_type
    }

    hash[:tag]               = tag if tag.present?
    hash[:search_terms]      = search_terms if search_terms.present?
    hash[:related_item_id]   = related_item_id if related_item_id.present?
    hash[:related_item_type] = related_item_type if related_item_type.present?
    hash[:user_id]           = user_id if user_id.present?

    hash
  end

  def default_content_item_type
    'Topic'
  end
end
