class AddEmbeddedToTopicTypeToFieldMapping < ActiveRecord::Migration
  def self.up
    add_column :topic_type_to_field_mappings, :embedded, :boolean
  end

  def self.down
    remove_column :topic_type_to_field_mappings, :embedded
  end
end
