class CreateTopics < ActiveRecord::Migration
  def self.up
    create_table :topics do |t|
      t.column :title, :string, null: false
      t.column :short_summary, :text
      t.column :description, :text
      t.column :extended_content, :text
      t.column :topic_type_id, :integer, null: false
      t.column :basket_id, :integer, null: false
      t.column :created_at, :datetime, null: false
      t.column :updated_at, :datetime, null: false
    end
  end

  def self.down
    drop_table :topics
  end
end
