class SearchResult

  include ActionView::Helpers::UrlHelper

  attr_reader :model

  def initialize(model)
    if model.class == PgSearch::Document
      # all/for searches
      @model = model.searchable
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
    related = {}

    if model.respond_to? :related_items_hash
      model.related_items_hash.each { |k, v| related[k.underscore.pluralize.to_sym] = v }
    end

    related
  end

  def related_items_summary
    related.map { |content_type, models|
      (models.count > 0) ? "#{models.count} #{content_type.to_s.humanize}" : nil
    }.compact.to_sentence
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
