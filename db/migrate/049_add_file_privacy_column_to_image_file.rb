class AddFilePrivacyColumnToImageFile < ActiveRecord::Migration
  def self.up
    add_column 'image_files', 'file_private', :boolean
  end

  def self.down
    remove_column 'image_files', 'file_private'
  end
end
