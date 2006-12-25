class AddImagesVersioning < ActiveRecord::Migration
  def self.up
    # create versioning table for images
    Image.create_versioned_table
  end

  def self.down
    Image.drop_versioned_table
  end
end
