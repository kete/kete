class CreateSearches < ActiveRecord::Migration
  def self.up
    create_table :searches do |t|
      t.integer :user_id, :null => false
      t.string :title, :null => false
      t.string :url, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :searches
  end
end
