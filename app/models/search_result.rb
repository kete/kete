class SearchResult

  include ActionView::Helpers::UrlHelper

  attr_reader :model

  def initialize(model, searched_topic_id)
    if model.class == PgSearch::Document
      # all/for searches
      @model = model.searchable
    elsif model.class == ContentItemRelation
      # related_to searches
      @model = dereference_content_item_relation(model, searched_topic_id)
    elsif model.class == Contribution
      @model = model.contributed_item
    else
      # tagged/etc searches
      @model = model
    end
  end

  def id
    (model.respond_to? :id) ? model.id : ""
  end

  def class 
    (model.respond_to? :class) ? model.class : ""
  end

  def title
    (model.respond_to? :title) ? model.title : ""
  end

  def short_summary
    (model.respond_to? :short_summary) ? model.short_summary : ""
  end

  def related
    (model.respond_to? :related) ? model.related : { counts: {} }
  end

  def locally_hosted
    (model.respond_to? :locally_hosted) ? model.locally_hosted : ""
  end

  def topic_types
    (model.respond_to? :topic_types) ? model.topic_types : []
  end

  def dc_dates
    (model.respond_to? :dc_dates) ? model.dc_dates : ""
  end

  def thumbnail
    (model.respond_to? :thumbnail) ? model.thumbnail : ""
  end

  private

  def dereference_content_item_relation(model, searched_topic_id)
    # Only lookup the topic if the related_item was
    # the thing searched for.
    if model.topic_id.to_s == searched_topic_id
      model.related_item
    else
      model.topic
    end
  end
end
