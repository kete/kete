class AddPrivateVersionAndSerializedColumnsToDocuments < ActiveRecord::Migration
  def self.up
    add_column 'documents', 'private_version', :integer
    add_column 'documents', 'private_version_serialized', :text
  end

  def self.down
    remove_column 'documents', 'private_version'
    remove_column 'documents', 'private_version_serialized'
  end
end
