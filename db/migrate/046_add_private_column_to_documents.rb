class AddPrivateColumnToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :private, :boolean
    add_column :document_versions, :private, :boolean
  end

  def self.down
    remove_column :documents, :private
    remove_column :document_versions, :private
  end
end
