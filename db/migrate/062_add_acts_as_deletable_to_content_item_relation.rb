class AddActsAsDeletableToContentItemRelation < ActiveRecord::Migration
  def self.up
    # Creating able manually as ::Deleted.create_table generates MySQL foreign keys for
    # all foreign key columns on the table due to foreign_key_migrations. This normally
    # causes a failure because related_items does not exist (see below).
    create_table 'deleted_content_item_relations' do |t|
      t.column 'position', :integer, default: nil
      t.column 'topic_id', :integer, default: nil
      t.column 'related_item_id', :integer, default: nil, references: nil
      t.column 'related_item_type', :string, default: nil
      t.column 'deleted_at', :datetime, default: nil
      t.timestamps
    end
  end

  def self.down
    drop_table 'deleted_content_item_relations'
  end
end
