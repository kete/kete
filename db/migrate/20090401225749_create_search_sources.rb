class CreateSearchSources < ActiveRecord::Migration
  def self.up
    create_table :search_sources do |t|
      t.string :title, :source_type, :base_url
      t.integer :limit

      t.timestamps
    end
  end

  def self.down
    drop_table :search_sources
  end
end
