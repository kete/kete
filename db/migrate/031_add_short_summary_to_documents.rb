class AddShortSummaryToDocuments < ActiveRecord::Migration
  def self.up
    add_column :documents, :short_summary, :text
    add_column :document_versions, :short_summary, :text
  end

  def self.down
    remove_column :document_versions, :short_summary
    remove_column :documents, :short_summary
  end
end
