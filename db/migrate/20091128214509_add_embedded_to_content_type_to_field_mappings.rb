class AddEmbeddedToContentTypeToFieldMappings < ActiveRecord::Migration
  def self.up
    add_column :content_type_to_field_mappings, :embedded, :boolean
  end

  def self.down
    remove_column :content_type_to_field_mappings, :embedded
  end
end
