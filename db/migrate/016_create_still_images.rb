class CreateStillImages < ActiveRecord::Migration
  def self.up
    create_table :still_images do |t|
      t.column :title, :string, :null => false
      t.column :description, :text
      t.column :extended_content, :text
      t.column :basket_id, :integer, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :still_images
  end
end
