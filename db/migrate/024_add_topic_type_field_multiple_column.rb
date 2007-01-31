class AddTopicTypeFieldMultipleColumn < ActiveRecord::Migration
  def self.up
    add_column :topic_type_fields, :multiple, :boolean, :default => false
  end

  def self.down
    remove_column :topic_type_fields, :multiple
  end
end
