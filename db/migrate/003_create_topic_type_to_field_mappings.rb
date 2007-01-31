class CreateTopicTypeToFieldMappings < ActiveRecord::Migration
  def self.up
    create_table :topic_type_to_field_mappings do |t|
      t.column :topic_type_id, :integer, :null => false
      t.column :extended_field_id, :integer, :null => false
      t.column :position, :integer, :null => false
      t.column :required, :boolean, :default => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :topic_type_to_field_mappings
  end
end
