class DropKeywords < ActiveRecord::Migration
  def self.up
    remove_column :topics, :keywords
  end

  def self.down
    add_column :topics, :keywords, :text
  end
end
