class RemoveEmbedExtendedFieldDataFromTopicTypes < ActiveRecord::Migration
  def self.up
    remove_column :topic_types, :embed_extended_field_data
  end

  def self.down
    add_column :topic_types, :embed_extended_field_data, :boolean
  end
end
