class CreateLicenses < ActiveRecord::Migration
  def self.up
    create_table :licenses do |t|
      t.string :name
      t.string :description
      t.string :url
      t.boolean :is_available
      t.string :image_url
      t.boolean :is_creative_commons
      t.text :metadata

      t.timestamps
    end
  end

  def self.down
    drop_table :licenses
  end
end
