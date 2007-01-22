class AddWebLinkVersioning < ActiveRecord::Migration
  def self.up
    # create versioning table for web_links
    WebLink.create_versioned_table
  end

  def self.down
    WebLink.drop_versioned_table
  end
end
