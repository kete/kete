class Searcher
  def initialize(query: SearchQuery.new)
    @query = query
  end

  def run
    all_class_results = PgSearch.multisearch(query.search_terms) # => ActiveRecord::Relation
    {
      'Topic'          => all_class_results.where(searchable_type: 'Topic'),
      'StillImage'     => all_class_results.where(searchable_type: 'StillImage'),
      'AudioRecording' => all_class_results.where(searchable_type: 'AudioRecording'),
      'Video'          => all_class_results.where(searchable_type: 'Video'),
      'WebLink'        => all_class_results.where(searchable_type: 'WebLink'),
      'Document'       => all_class_results.where(searchable_type: 'Document'),
      'Comment'        => all_class_results.where(searchable_type: 'Comment')
    }
  end

  def all
    ##
    # In a somewhat confusing move, old kete makes searching the 'site' basket
    # actually search all baskets so we special case the 'site' basket here to
    # maintain compatibility.
    if query.basket_name == 'site'
      results = {
        'Topic'          => Topic.order('updated_at DESC'),
        'StillImage'     => StillImage.order('updated_at DESC'),
        'AudioRecording' => AudioRecording.order('updated_at DESC'),
        'Video'          => Video.order('updated_at DESC'),
        'WebLink'        => WebLink.order('updated_at DESC'),
        'Document'       => Document.order('updated_at DESC'),
        'Comment'        => Comment.order('updated_at DESC'),
      }
    else
      {
        'Topic'          => Topic.joins(:basket).where(baskets: { urlified_name: query.basket_name }).order('updated_at DESC'),
        'StillImage'     => StillImage.joins(:basket).where(baskets: { urlified_name: query.basket_name }).order('updated_at DESC'),
        'AudioRecording' => AudioRecording.joins(:basket).where(baskets: { urlified_name: query.basket_name }).order('updated_at DESC'),
        'Video'          => Video.joins(:basket).where(baskets: { urlified_name: query.basket_name }).order('updated_at DESC'),
        'WebLink'        => WebLink.joins(:basket).where(baskets: { urlified_name: query.basket_name }).order('updated_at DESC'),
        'Document'       => Document.joins(:basket).where(baskets: { urlified_name: query.basket_name }).order('updated_at DESC'),
        'Comment'        => Comment.joins(:basket).where(baskets: { urlified_name: query.basket_name }).order('updated_at DESC'),
      }
    end
  end

  def tagged
    {
      'Topic'          => Topic.tagged_with(query.tag).order('updated_at DESC'),
      'StillImage'     => StillImage.tagged_with(query.tag).order('updated_at DESC'),
      'AudioRecording' => AudioRecording.tagged_with(query.tag).order('updated_at DESC'),
      'Video'          => Video.tagged_with(query.tag).order('updated_at DESC'),
      'WebLink'        => WebLink.tagged_with(query.tag).order('updated_at DESC'),
      'Document'       => Document.tagged_with(query.tag).order('updated_at DESC'),
      'Comment'        => Comment.tagged_with(query.tag).order('updated_at DESC'),
    }
  end

  def contributed_by
    # This could also be scopped by contributor_role: "contributor"/"creator"
    distinct_contributions = Contribution.select('DISTINCT user_id, contributed_item_type, contributed_item_id')
                                         .order(:contributed_item_type, :contributed_item_id)
                                         .where(user_id: query.user_id)
    {
      'Topic'          => distinct_contributions.where(contributed_item_type: 'Topic'),
      'StillImage'     => distinct_contributions.where(contributed_item_type: 'StillImage'),
      'AudioRecording' => distinct_contributions.where(contributed_item_type: 'AudioRecording'),
      'Video'          => distinct_contributions.where(contributed_item_type: 'Video'),
      'WebLink'        => distinct_contributions.where(contributed_item_type: 'WebLink'),
      'Document'       => distinct_contributions.where(contributed_item_type: 'Document'),
      'Comment'        => distinct_contributions.where(contributed_item_type: 'Comment'),
    }
  end

  def related
    if related_to_class == 'Topic'
      related_to_topics_hash
    else
      topics_related_to_class_hash
    end
  end

  def related_to
    if query.related_item_topic_query?
      related_to_topic_hash
    else
      related_to_non_topic_hash
    end
  end

  private

  attr_reader :query

  def empty_relation
    ContentItemRelation.where('1=2')
  end

  def related_to_topic_hash
    related_by_topic        = ContentItemRelation.where(topic_id: query.related_item_id)
    related_by_content_item = ContentItemRelation.where(related_item_type: 'Topic')
                                                 .where(related_item_id: query.related_item_id)

    # Help arel form an OR statement.
    related_by_topic = related_by_topic.where_values.reduce(:and)
    related_by_content_item = related_by_content_item.where_values.reduce(:and)

    related_to_topic = ContentItemRelation.where(related_by_content_item.or(related_by_topic)).order('position DESC')

    {
      'Topic'          => related_to_topic.where(related_item_type: 'Topic'),
      'StillImage'     => related_to_topic.where(related_item_type: 'StillImage'),
      'AudioRecording' => related_to_topic.where(related_item_type: 'AudioRecording'),
      'Video'          => related_to_topic.where(related_item_type: 'Video'),
      'WebLink'        => related_to_topic.where(related_item_type: 'WebLink'),
      'Document'       => related_to_topic.where(related_item_type: 'Document'),
      'Comment'        => related_to_topic.where(related_item_type: 'Comment'),
    }
  end

  def related_to_non_topic_hash
    topics_related_to = ContentItemRelation.where(related_item_id: query.related_item_id)
                                           .where(related_item_type: query.related_item_type)
                                           .order('position DESC')
    {
      'Topic'          => topics_related_to,
      'StillImage'     => empty_relation,
      'AudioRecording' => empty_relation,
      'Video'          => empty_relation,
      'WebLink'        => empty_relation,
      'Document'       => empty_relation,
      'Comment'        => empty_relation,
    }
  end
end
