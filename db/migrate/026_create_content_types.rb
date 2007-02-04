class CreateContentTypes < ActiveRecord::Migration
  def self.up
    create_table :content_types do |t|
      t.column :class_name, :string, :null => false
      t.column :controller, :string, :null => false
      t.column :humanized, :string, :null => false
      t.column :humanized_plural, :string, :null => false
      t.column :description, :text, :null => false
    end
  end

  def self.down
    drop_table :content_types
  end
end
