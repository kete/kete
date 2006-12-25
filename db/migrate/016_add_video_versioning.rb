class AddVideoVersioning < ActiveRecord::Migration
  def self.up
    # create versioning table for videos
    Video.create_versioned_table
  end

  def self.down
    Video.drop_versioned_table
  end
end
