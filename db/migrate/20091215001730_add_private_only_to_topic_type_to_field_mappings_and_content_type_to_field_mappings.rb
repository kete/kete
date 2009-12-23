class AddPrivateOnlyToTopicTypeToFieldMappingsAndContentTypeToFieldMappings < ActiveRecord::Migration
  def self.up
    add_column :topic_type_to_field_mappings, :private_only, :boolean
    add_column :content_type_to_field_mappings, :private_only, :boolean
  end

  def self.down
    remove_column :topic_type_to_field_mappings, :private_only
    remove_column :content_type_to_field_mappings, :private_only
  end
end
