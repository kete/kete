class AddAudioRecordingVersioning < ActiveRecord::Migration
  def self.up
    # create versioning table for audio_recordings
    AudioRecording.create_versioned_table
  end

  def self.down
    AudioRecording.drop_versioned_table
  end
end
