class RemovePrivateVersionFromDocuments < ActiveRecord::Migration
  def self.up
    remove_column 'documents', 'private_version'
  end

  def self.down
    add_column 'documents', 'private_version', :integer
  end
end
