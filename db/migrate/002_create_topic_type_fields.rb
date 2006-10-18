class CreateTopicTypeFields < ActiveRecord::Migration
  def self.up
    create_table :topic_type_fields do |t|
      t.column :name, :string, :null => false
      t.column :description, :text
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :topic_type_fields
  end
end
