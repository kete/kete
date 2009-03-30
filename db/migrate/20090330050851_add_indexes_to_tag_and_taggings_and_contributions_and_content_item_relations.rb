class AddIndexesToTagAndTaggingsAndContributionsAndContentItemRelations < ActiveRecord::Migration
  def self.up
    add_index :content_item_relations, :related_item_id
    add_index :contributions, :contributed_item_id
    add_index :taggings, :taggable_id
    add_index :tags, :name
  end

  def self.down
    remove_index :content_item_relations, :related_item_id
    remove_index :contributions, :contributed_item_id
    remove_index :taggings, :taggable_id
    remove_index :tags, :name
  end
end
