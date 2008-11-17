class AddSerializedFeedToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :serialized_feed, :mediumtext
    add_column :feeds, :update_frequency, :float
  end

  def self.down
    remove_column :feeds, :serialized_feed
    remove_column :feeds, :update_frequency
  end
end
