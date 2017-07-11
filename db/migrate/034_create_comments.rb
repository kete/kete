class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.column :title, :string, null: false
      t.column :description, :text
      t.column :extended_content, :text
      t.column :position, :integer, null: false
      t.column :commentable_id, :integer, null: false, references: nil
      t.column :commentable_type, :string, null: false
      t.column :basket_id, :integer, null: false
      t.column :created_at, :datetime, null: false
      t.column :updated_at, :datetime, null: false
    end
    ContentType.create! class_name: 'Comment',
    description: 'Where we store comments on items and topics, also known as discussion.',
    humanized_plural: 'Discussion',
    controller: 'comments',
    humanized: 'Discussion'
  end

  def self.down
    ContentType.find_by_class_name('Comment').destroy
    drop_table :comments
  end
end
