class AddVersioningToWebLinks < ActiveRecord::Migration
  def self.up
    # create versioning table for topics
    WebLink.create_versioned_table
  end

  def self.down
    WebLink.drop_versioned_table
  end
end
