class AddNestedSetFieldsToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :parent_id, :integer, null: true, references: nil
    add_column :comments, :lft, :integer
    add_column :comments, :rgt, :integer
    remove_column :comments, :position
  end

  def self.down
    remove_column :comments, :rgt
    remove_column :comments, :lft
    remove_column :comments, :parent_id
    add_column :comments, :position
  end
end
