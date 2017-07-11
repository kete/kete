class Captcha < ActiveRecord::Migration
  def self.up
    create_table :captchas do |t|
      t.column :text,       :string, limit: 25, null: false
      t.column :imageblob,  :binary, null: false
      t.column :created_at, :timestamp, null: false
    end
  end

  def self.down
    drop_table :captchas
  end
end
