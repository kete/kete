class AddImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.column :title, :string, :null => false
      t.column :description, :text
      t.column :filename, :string, :null => false
      t.column :content_type, :string, :null => false
      t.column :size, :integer, :null => false
      # doing parent_id as a separate step,
      # after we do versioning
      t.column :thumbnail, :string
      t.column :width, :integer
      t.column :height, :integer
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :images
  end
end
