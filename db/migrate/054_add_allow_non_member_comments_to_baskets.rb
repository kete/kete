class AddAllowNonMemberCommentsToBaskets < ActiveRecord::Migration
  def self.up
    add_column 'baskets', 'allow_non_member_comments', :boolean
  end

  def self.down
    remove_column 'baskets', 'allow_non_member_comments'
  end
end
