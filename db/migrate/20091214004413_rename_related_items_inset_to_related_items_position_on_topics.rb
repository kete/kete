class RenameRelatedItemsInsetToRelatedItemsPositionOnTopics < ActiveRecord::Migration
  def self.up
    rename_column :topics, :related_items_inset, :related_items_position
    change_column :topics, :related_items_position, :text
    rename_column :topic_versions, :related_items_inset, :related_items_position
    change_column :topic_versions, :related_items_position, :text
  end

  def self.down
    rename_column :topics, :related_items_position, :related_items_inset
    change_column :topics, :related_items_inset, :boolean
    rename_column :topic_versions, :related_items_position, :related_items_inset
    change_column :topic_versions, :related_items_inset, :boolean
  end
end
