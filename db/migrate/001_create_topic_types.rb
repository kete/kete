class CreateTopicTypes < ActiveRecord::Migration
  def self.up
    create_table :topic_types do |t|
      t.column :name, :string, :null => false
      t.column :description, :text, :null => false
      t.column :parent_id, :integer, :references => nil
      t.column :lft, :integer
      t.column :rgt, :integer
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :topic_types
  end
end
