class AddDocumentVersioning < ActiveRecord::Migration
  def self.up
    Document.create_versioned_table
  end

  def self.down
    Document.drop_versioned_table
  end
end
