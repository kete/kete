class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics do |t|
      t.column :name_for_url, :string, :null => false
      t.column :description, :text
      t.column :content, :text
      t.column :topic_type_id, :integer, :null => false
      t.column :created_at, :datetime, :null => false
      t.column :updated_at, :datetime, :null => false
    end
  end

  def self.down
    drop_table :topics
  end
end
