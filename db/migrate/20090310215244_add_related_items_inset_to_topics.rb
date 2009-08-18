class AddRelatedItemsInsetToTopics < ActiveRecord::Migration
  def self.up
    add_column :topics, :related_items_inset, :boolean
    add_column :topic_versions, :related_items_inset, :boolean
  end

  def self.down
    remove_column :topics, :related_items_inset
    remove_column :topic_versions, :related_items_inset
  end
end
