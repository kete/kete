class ContentItemRelation < ActiveRecord::Base
  # this is where we store our polymorphic "related to" between topics and items, and topics and topics
  belongs_to :topic
  belongs_to :related_item, :polymorphic => true
  # by using has_many :through associations we gain some bidirectional flexibility
  # with our polymorphic join model
  # basicaly specifically name the classes on the other side of the relationship here
  # see http://blog.hasmanythrough.com/articles/2006/04/03/polymorphic-through
  belongs_to :web_link, :class_name => "WebLink", :foreign_key => "related_item_id"
  # a topic can be related to another topic
  belongs_to :related_topic, :class_name => "Topic", :foreign_key => "related_item_id"

  acts_as_list

  def self.new_relation_to_topic(topic_id, related_item)
      content_item_relation = self.new(:topic_id => topic_id)
      content_item_relation.related_item = related_item
      content_item_relation.save!
  end
end
