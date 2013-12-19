class SearchResult

  include ActionView::Helpers::UrlHelper

  attr_reader :model

  def initialize(model)
    @model = model
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
end