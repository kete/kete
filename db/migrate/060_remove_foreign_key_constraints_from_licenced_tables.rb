class RemoveForeignKeyConstraintsFromLicencedTables < ActiveRecord::Migration
  def self.up
    # Removing foreign key constraints mistakenly added in a previous migration
    remove_column 'audio_recordings', 'license_id'
    remove_column 'videos', 'license_id'
    remove_column 'documents', 'license_id'
    remove_column 'web_links', 'license_id'
    remove_column 'still_images', 'license_id'
    remove_column 'topics', 'license_id'
    remove_column 'users', 'license_id'
    
    # Add the columns again without foreign keys
    add_column 'audio_recordings', 'license_id', :integer, references: nil
    add_column 'videos', 'license_id', :integer, references: nil
    add_column 'documents', 'license_id', :integer, references: nil
    add_column 'web_links', 'license_id', :integer, references: nil
    add_column 'still_images', 'license_id', :integer, references: nil
    add_column 'topics', 'license_id', :integer, references: nil
    add_column 'users', 'license_id', :integer, references: nil
  end

  def self.down
    remove_column 'audio_recordings', 'license_id'
    remove_column 'videos', 'license_id'
    remove_column 'documents', 'license_id'
    remove_column 'web_links', 'license_id'
    remove_column 'still_images', 'license_id'
    remove_column 'topics', 'license_id'
    remove_column 'users', 'license_id'
    
    add_column 'audio_recordings', 'license_id', :integer
    add_column 'videos', 'license_id', :integer
    add_column 'documents', 'license_id', :integer
    add_column 'web_links', 'license_id', :integer
    add_column 'still_images', 'license_id', :integer
    add_column 'topics', 'license_id', :integer
    add_column 'users', 'license_id', :integer
  end
end
