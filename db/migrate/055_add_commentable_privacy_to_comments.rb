class AddCommentablePrivacyToComments < ActiveRecord::Migration
  def self.up
    add_column 'comments', 'commentable_private', :boolean
  end

  def self.down
    remove_column 'comments', 'commentable_private'
  end
end
