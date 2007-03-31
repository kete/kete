class AddCommentVersioning < ActiveRecord::Migration
  def self.up
    Comment.create_versioned_table
  end

  def self.down
    Comment.drop_versioned_table
  end
end
