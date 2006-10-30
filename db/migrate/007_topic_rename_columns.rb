class TopicRenameColumns < ActiveRecord::Migration
  def self.up
    rename_column :topics, :name_for_url, :title
    add_column :topics, :short_summary, :text
    add_column :topics, :keywords, :text
    # handle versioning table
    rename_column :topic_versions, :name_for_url, :title
    add_column :topic_versions, :short_summary, :text
    add_column :topic_versions, :keywords, :text
  end

  def self.down
    rename_column :topics, :title, :name_for_url
    remove_column :topics, :short_summary
    remove_column :topics, :keywords
    # handle versioning table
    rename_column :topic_versions, :title, :name_for_url
    remove_column :topic_versions, :short_summary
    remove_column :topic_versions, :keywords
  end
end
