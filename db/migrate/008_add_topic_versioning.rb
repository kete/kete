class AddTopicVersioning < ActiveRecord::Migration
  def self.up
    # create versioning table for topics
    Topic.create_versioned_table
  end

  def self.down
    Topic.drop_versioned_table
  end
end
