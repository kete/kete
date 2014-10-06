class AddIndexesToUpdatedAtForManyModels < ActiveRecord::Migration
  # Speed up horribly slow Topic.updated_since query
  def change
    add_index :topics,                         :updated_at
    add_index :taggings,                       :created_at
    add_index :contributions,                  :updated_at
    add_index :content_item_relations,         :updated_at
    add_index :deleted_content_item_relations, :updated_at
  end
end
