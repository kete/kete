class AddImageThumbs < ActiveRecord::Migration
  def self.up
    create_table :image_thumbs do |t|
      t.column :parent_id, :integer, :references => :images
      t.column :thumbnail, :string, :null => false
      t.column :filename, :string, :null => false
      t.column :content_type, :string, :null => false
      t.column :size, :integer, :null => false
      t.column :width, :integer
      t.column :height, :integer
    end
  end

  def self.down
    drop_table :image_thumbs
  end
end
