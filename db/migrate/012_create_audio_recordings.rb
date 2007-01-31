class CreateAudioRecordings < ActiveRecord::Migration
  def self.up
    create_table :audio_recordings do |t|
      t.column :title, :string, :null => false
      t.column :description, :text
      t.column :extended_content, :text
      t.column :filename, :string, :null => false
      t.column :content_type, :string, :null => false
      t.column :size, :integer, :null => false
      t.column :basket_id, :integer, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :audio_recordings
  end
end
