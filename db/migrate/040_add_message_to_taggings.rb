class AddMessageToTaggings < ActiveRecord::Migration
  def self.up
    add_column :taggings, :message, :text
  end

  def self.down
    remove_column :taggings, :message
  end
end
