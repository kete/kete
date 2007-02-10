class ContentItemRelation < ActiveRecord::Base
  # this is where we store our polymorphic "related to" between topics and items, and topics and topics
  belongs_to :topic
  belongs_to :related_item, :polymorphic => true
  # by using has_many :through associations we gain some bidirectional flexibility
  # with our polymorphic join model
  # basicaly specifically name the classes on the other side of the relationship here
  # see http://blog.hasmanythrough.com/articles/2006/04/03/polymorphic-through
  ZOOM_CLASSES.each do |zoom_class|
    if zoom_class == 'Topic'
      # a topic can be related to another topic
      # but it needs a special name
      belongs_to :related_topic, :class_name => "Topic", :foreign_key => "related_item_id"
    else
      belongs_to zoom_class.tableize.singularize.to_sym, :class_name => zoom_class, :foreign_key => "related_item_id"
    end
  end

  acts_as_list :scope => :topic_id

  # wish we could update the topic and new relation
  # in zoom here
  # so that this relationship is reflected in searches
  # but it has to be done in controller space because it requires a render
  def self.new_relation_to_topic(topic_id, related_item)
    logger.debug("what is topic_id: #{topic_id}")
    content_item_relation = self.new(:topic_id => topic_id)
    logger.debug("what is topic_id: #{content_item_relation.topic_id}")
    content_item_relation.related_item = related_item
    content_item_relation.save!
  end
end
