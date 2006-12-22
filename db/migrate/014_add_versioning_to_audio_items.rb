class AddVersioningToAudioItems < ActiveRecord::Migration
  def self.up
    # create versioning table for audio_items
    AudioItem.create_versioned_table
  end

  def self.down
    AudioItem.drop_versioned_table
  end
end
