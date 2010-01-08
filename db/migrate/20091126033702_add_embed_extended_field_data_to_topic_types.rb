class AddEmbedExtendedFieldDataToTopicTypes < ActiveRecord::Migration
  def self.up
    add_column :topic_types, :embed_extended_field_data, :boolean
  end

  def self.down
    remove_column :topic_types, :embed_extended_field_data
  end
end
