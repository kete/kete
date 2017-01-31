class AddPrivateAndFilePrivateToItemModels < ActiveRecord::Migration
  def self.up
    # Columns for audio_recordings
    add_column 'audio_recordings', 'private', :boolean
    add_column 'audio_recordings', 'file_private', :boolean
    add_column 'audio_recording_versions', 'private', :boolean

    # Columns for still_images
    add_column 'still_images', 'private', :boolean
    add_column 'still_images', 'file_private', :boolean
    add_column 'still_image_versions', 'private', :boolean

    # Columns for topics
    add_column 'topics', 'private', :boolean
    add_column 'topic_versions', 'private', :boolean

    # Columns for web_links
    add_column 'web_links', 'private', :boolean
    add_column 'web_links', 'file_private', :boolean
    add_column 'web_link_versions', 'private', :boolean

    add_column 'videos', 'private', :boolean
    add_column 'videos', 'file_private', :boolean
    add_column 'video_versions', 'private', :boolean

    # Documents already covered in migration #046 and #047
  end

  def self.down
    # Columns for audio_recordings
    remove_column 'audio_recordings', 'private'
    remove_column 'audio_recordings', 'file_private'
    remove_column 'audio_recording_versions', 'private'

    # Columns for still_images
    remove_column 'still_images', 'private'
    remove_column 'still_images', 'file_private'
    remove_column 'still_image_versions', 'private'

    # Columns for topics
    remove_column 'topics', 'private'
    remove_column 'topic_versions', 'private'

    # Columns for web_links
    remove_column 'web_links', 'private'
    remove_column 'web_links', 'file_private'
    remove_column 'web_link_versions', 'private'

    # Columns for videos
    remove_column 'videos', 'private'
    remove_column 'videos', 'file_private'
    remove_column 'video_versions', 'private'

    # Documents already covered in migration #046 and #047
  end
end
