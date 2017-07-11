class CreateContributions < ActiveRecord::Migration
  def self.up
    # a user can have multiple contributions to the same thing
    # they may contribute in different roles
    # or different versions
    create_table :contributions do |t|
      t.column :user_id, :integer, null: false
      t.column :contributed_item_id, :integer, null: false, references: nil
      t.column :contributed_item_type, :string, null: false
      t.column :contributor_role, :string, null: false
      t.column :version, :integer, null: false
      t.column :created_at, :datetime, null: false
      t.column :updated_at, :datetime, null: false
    end
  end

  def self.down
    drop_table :contributions
  end
end
