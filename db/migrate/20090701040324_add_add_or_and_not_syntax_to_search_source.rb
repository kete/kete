class AddAddOrAndNotSyntaxToSearchSource < ActiveRecord::Migration
  def self.up
    add_column :search_sources, :or_syntax, :text
    add_column :search_sources, :and_syntax, :text
    add_column :search_sources, :not_syntax, :text
  end

  def self.down
    remove_column :search_sources, :not_syntax
    remove_column :search_sources, :and_syntax
    remove_column :search_sources, :or_syntax
  end
end
