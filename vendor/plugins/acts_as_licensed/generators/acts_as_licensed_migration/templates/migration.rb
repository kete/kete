class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table "<%= migration_table_name %>" do |t|
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
    drop_table "<%= migration_table_name %>"
  end
end
