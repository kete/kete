class AddAudioRecordingVersioning < ActiveRecord::Migration
  def self.up
    # create versioning table for audio_recordings
    Audiorecording.create_versioned_table
  end

  def self.down
    Audiorecording.drop_versioned_table
  end
end
