class CreateContentTypeToFieldMappings < ActiveRecord::Migration
  def self.up
    create_table :content_type_to_field_mappings do |t|
      t.column :content_type_id, :integer, :null => false
      t.column :extended_field_id, :integer, :null => false
      t.column :position, :integer, :null => false
      t.column :required, :boolean, :default => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :content_type_to_field_mappings
  end
end
