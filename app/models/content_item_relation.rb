class ContentItemRelation < ActiveRecord::Base
  # this is where we store our polymorphic "related to" between topics and items, and topics and topics
  belongs_to :topic
  belongs_to :related_item, polymorphic: true
  # by using has_many :through associations we gain some bidirectional flexibility
  # with our polymorphic join model
  # basicaly specifically name the classes on the other side of the relationship here
  # see http://blog.hasmanythrough.com/articles/2006/04/03/polymorphic-through
  ZOOM_CLASSES.each do |zoom_class|
    if zoom_class == 'Topic'
      # a topic can be related to another topic
      # but it needs a special name
      belongs_to :child_related_topic, class_name: 'Topic', foreign_key: 'related_item_id'
    else
      belongs_to zoom_class.tableize.singularize.to_sym, class_name: zoom_class, foreign_key: 'related_item_id'
    end
  end

  acts_as_list scope: :topic_id

  # Keep deleted instances in ContentItemRelation::Deleted instead of removing them
  # from table.
  acts_as_soft_deletable

  # wish we could update the topic and new relation
  # in zoom here
  # so that this relationship is reflected in searches
  # but it has to be done in controller space because it requires a render
  def self.new_relation_to_topic(topic_id, related_item)
    # Undestroy a previous version if present, rather than creating a new relationship.
    if content_item_relation = find_relation_to_topic(topic_id, related_item, deleted: true)
      content_item_relation.undestroy!

    else
      content_item_relation = create!(
        # Handle topic_id being passed in as Topic instead of Integer or String.
        topic_id: topic_id.is_a?(Topic) ? topic_id.id : topic_id,
        related_item: related_item
      ) unless find_relation_to_topic(topic_id, related_item)
    end
  end

  def self.destroy_relation_to_topic(topic_id, related_item)
    relation = find_relation_to_topic(topic_id, related_item)
    relation.destroy unless relation.blank?
  end

  protected

  def self.find_relation_to_topic(topic_id, related_item, options = {})
    topic_id = topic_id.is_a?(Topic) ? topic_id.id : topic_id
    options = { deleted: false }.merge(options)

    # Set the class to run the find on.
    find_class = options[:deleted] ? ContentItemRelation::Deleted : ContentItemRelation

    if related_item.instance_of?(Topic)
      relation = find_class.where(topic_id: related_item.id).where(related_item_id: topic_id).where(related_item_type: 'Topic').first
    end

    # If no relationship has been found above, check the correct way around.
    relation ||= find_class.where(topic_id: topic_id).where(related_item_id: related_item.id).where(related_item_type: "#{related_item.class.name}").first
  end
end
