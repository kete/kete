class AddStillImageVersioning < ActiveRecord::Migration
  def self.up
    # create versioning table for images
    StillImage.create_versioned_table
  end

  def self.down
    StillImage.drop_versioned_table
  end
end
