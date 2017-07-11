class AddRelatedTopicTypeIdToImports < ActiveRecord::Migration
  def self.up
    add_column :imports, :related_topic_type_id, :integer, references: nil
  end

  def self.down
    remove_column :imports, :related_topic_type_id
  end
end
