class TopicRenameColumns < ActiveRecord::Migration
  def self.up
    rename_column :topics, :name_for_url, :name
    rename_column :topics, :description, :short_summary
    add_column :topics, :description, :text
    add_column :topics, :keywords, :text
  end

  def self.down
    rename_column :topics, :name, :name_for_url
    rename_column :topics, :short_summary, :description
    remove_column :topics, :description
    remove_column :topics, :keywords
  end
end
