class AddLicenseIdToRemainingModels < ActiveRecord::Migration
  def self.up
    add_column 'audio_recordings', 'license_id', :integer
    add_column 'videos', 'license_id', :integer
    add_column 'documents', 'license_id', :integer
    add_column 'web_links', 'license_id', :integer
    add_column 'still_images', 'license_id', :integer
  end

  def self.down
    remove_column 'audio_recordings', 'license_id'
    remove_column 'videos', 'license_id'
    remove_column 'documents', 'license_id'
    remove_column 'web_links', 'license_id'
    remove_column 'still_images', 'license_id'
  end
end
