class AddAudioItems < ActiveRecord::Migration
  def self.up
    create_table :audio_items do |t|
      t.column :title, :string, :null => false
      t.column :description, :text
      t.column :content_type, :string, :limit => 100
      t.column :filename,     :string, :limit => 255
      t.column :path,         :string, :limit => 255
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :audio_items
  end
end
