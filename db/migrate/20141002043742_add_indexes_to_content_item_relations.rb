class AddIndexesToContentItemRelations < ActiveRecord::Migration
  def change
    add_index :content_item_relations, :topic_id
    add_index :content_item_relations, :related_item_id
    add_index :content_item_relations, :related_item_type
  end
end
