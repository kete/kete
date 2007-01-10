class DropKeywords < ActiveRecord::Migration
  def self.up
    remove_column :topics, :keywords
    remove_column :topic_versions, :keywords
  end

  def self.down
    add_column :topics, :keywords, :text
    add_column :topic_versions, :keywords, :text
  end
end
