class AddDisplayNameAndResolvedNameToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :display_name, :string
    add_column :users, :resolved_name, :string, null: false
  end

  def self.down
    remove_column :users, :display_name
    remove_column :users, :resolved_name
  end
end
