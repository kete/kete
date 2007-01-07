class AddBasketIds < ActiveRecord::Migration
  def self.up
    add_column :topics, :basket_id, :integer
    add_column :topic_versions, :basket_id, :integer
    add_column :web_links, :basket_id, :integer
    add_column :web_link_versions, :basket_id, :integer
    add_column :audio_recordings, :basket_id, :integer
    add_column :audio_recording_versions, :basket_id, :integer
    add_column :videos, :basket_id, :integer
    add_column :video_versions, :basket_id, :integer
    add_column :still_images, :basket_id, :integer
    add_column :still_image_versions, :basket_id, :integer
    add_column :image_files, :basket_id, :integer
  end

  def self.down
    remove_column :image_files, :basket_id
    remove_column :still_image_versions, :basket_id
    remove_column :still_images, :basket_id
    remove_column :video_versions, :basket_id
    remove_column :videos, :basket_id
    remove_column :audio_recording_versions, :basket_id
    remove_column :audio_recordings, :basket_id
    remove_column :web_link_versions, :basket_id
    remove_column :web_links, :basket_id
    remove_column :topic_versions, :basket_id
    remove_column :topics, :basket_id
  end
end
