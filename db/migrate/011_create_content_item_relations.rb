class CreateContentItemRelations < ActiveRecord::Migration
  def self.up
    create_table :content_item_relations do |t|
      t.column :position, :integer, :null => false
      t.column :topic_id, :integer, :null => false
      t.column :related_item_id, :integer, :null => false, :references => nil
      t.column :related_item_type, :string, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :content_item_relations
  end
end
