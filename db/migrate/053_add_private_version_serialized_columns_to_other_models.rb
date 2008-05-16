class AddPrivateVersionSerializedColumnsToOtherModels < ActiveRecord::Migration
  def self.up
    
    # Add columns for storing private version across models included
    # in privacy controls work
    add_column 'audio_recordings',  'private_version_serialized', :text
    add_column 'still_images',      'private_version_serialized', :text
    add_column 'topics',            'private_version_serialized', :text
    add_column 'videos',            'private_version_serialized', :text
    add_column 'web_links',         'private_version_serialized', :text
  end

  def self.down
    remove_column 'audio_recordings',  'private_version_serialized'
    remove_column 'still_images',      'private_version_serialized'
    remove_column 'topics',            'private_version_serialized'
    remove_column 'videos',            'private_version_serialized'
    remove_column 'web_links',         'private_version_serialized'
  end
end
