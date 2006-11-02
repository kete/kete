class CreateContentRelations < ActiveRecord::Migration
  def self.up
    create_table :content_relations do |t|
      t.column :position, :integer, :null => false
      t.column :topic_id, :integer, :null => false
      t.column :related_content_id, :integer, :null => false, :references => nil
      t.column :related_content_type, :string, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :content_relations
  end
end
