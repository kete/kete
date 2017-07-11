class CreateTagsAndTaggings < ActiveRecord::Migration
  def self.up
    create_table :tags, force: true do |t|
      t.column :name, :string, null: false
    end

    create_table :taggings, force: true do |t|
      t.column :tag_id, :integer, null: false
      t.column :taggable_id, :integer, null: false, references: nil
      t.column :taggable_type, :string, null: false
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :taggings
    drop_table :tags
  end
end
