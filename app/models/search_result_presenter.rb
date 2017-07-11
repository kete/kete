class SearchResultPresenter
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
    (model.respond_to? :id) ? model.id : ''
  end

  def class
    (model.respond_to? :class) ? model.class : ''
  end

  def title
    (model.respond_to? :title) ? model.title : ''
  end

  def short_summary
    summary = ''

    if model.respond_to? :description
      summary = model.description || ''
    elsif model.respond_to? :short_summary
      summary = model.short_summary || ''
    end

    summary.sanitize.truncate(180, omission: '...')
  end

  def has_related_items?
    return false if model.is_a? Comment
    model.respond_to? :related_items_hash
  end

  # This method mimics the return value of the Zoom controller code that built
  # the related items structure in the old Kete.
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
    (model.respond_to? :locally_hosted) ? model.locally_hosted : ''
  end

  def topic_types
    (model.respond_to? :topic_types) ? model.topic_types : []
  end

  def dc_dates
    (model.respond_to? :dc_dates) ? model.dc_dates : ''
  end

  def thumbnail
    (model.respond_to? :thumbnail) ? model.thumbnail : ''
  end

  def thumbnail_file
    (model.respond_to? :thumbnail_file) ? model.thumbnail_file : ''
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
