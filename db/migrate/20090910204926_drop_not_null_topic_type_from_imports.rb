class DropNotNullTopicTypeFromImports < ActiveRecord::Migration
  def self.up
    # not all import types need a topic type
    change_column :imports, :topic_type_id, :integer, :null => true
  end

  def self.down
    change_column :imports, :topic_type_id, :integer, :null => false
  end
end
