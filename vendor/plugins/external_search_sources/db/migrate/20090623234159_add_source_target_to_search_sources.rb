class AddSourceTargetToSearchSources < ActiveRecord::Migration
  def self.up
    add_column :search_sources, :source_target, :string
  end

  def self.down
    remove_column :search_sources, :source_target
  end
end
