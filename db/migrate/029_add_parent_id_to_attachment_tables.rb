class AddParentIdToAttachmentTables < ActiveRecord::Migration
  def self.up
    add_column :documents, :parent_id, :integer, :references => nil
    add_column :document_versions, :parent_id, :integer, :references => nil
    add_column :videos, :parent_id, :integer, :references => nil
    add_column :video_versions, :parent_id, :integer, :references => nil
    add_column :audio_recordings, :parent_id, :integer, :references => nil
    add_column :audio_recording_versions, :parent_id, :integer, :references => nil
  end

  def self.down
    remove_column :documents, :parent_id
    remove_column :document_versions, :parent_id
    remove_column :videos, :parent_id
    remove_column :video_versions, :parent_id
    remove_column :audio_recordings, :parent_id
    remove_column :audio_recording_versions, :parent_id
  end
end
