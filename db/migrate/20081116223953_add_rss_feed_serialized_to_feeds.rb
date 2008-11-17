class AddRssFeedSerializedToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :rss_feed_serialized, :mediumtext
  end

  def self.down
    remove_column :feeds, :rss_feed_serialized
  end
end
