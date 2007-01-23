class AddTopicTypeNestedSetFields < ActiveRecord::Migration
  def self.up
    add_column :topic_types, :parent_id, :integer, :references => nil
    add_column :topic_types, :lft, :integer
    add_column :topic_types, :rgt, :integer
  end

  def self.down
    remove_column :topic_types, :parent_id
    remove_column :topic_types, :lft
    remove_column :topic_types, :rgt
  end
end
