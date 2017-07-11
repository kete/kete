class CreateImageFiles < ActiveRecord::Migration
  def self.up
    create_table :image_files do |t|
      # still_image model holds meta data about an image
      # image_files is only for the actual binary files
      # including thumbnails
      t.column :still_image_id, :integer
      # parent_id is the original version of the file
      t.column :parent_id, :integer, references: nil
      t.column :thumbnail, :string
      t.column :filename, :string, null: false
      t.column :content_type, :string, null: false
      t.column :size, :integer, null: false
      t.column :width, :integer
      t.column :height, :integer
    end
  end

  def self.down
    drop_table :image_files
  end
end
