class AddRelatedTopicTypeIdToImports < ActiveRecord::Migration
  def self.up
    add_column :imports, :related_topic_type_id, :integer
  end

  def self.down
    remove_column :imports, :related_topic_type_id
  end
end
