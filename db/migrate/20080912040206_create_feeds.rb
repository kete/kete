class CreateFeeds < ActiveRecord::Migration
  def self.up
    create_table :feeds do |t|
      t.string :title, :url
      t.integer :limit, :basket_id
      t.datetime :last_downloaded

      t.timestamps
    end
  end

  def self.down
    drop_table :feeds
  end
end
