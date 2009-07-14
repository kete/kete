class AddPositionToSearchSource < ActiveRecord::Migration
  def self.up
    add_column :search_sources, :position, :integer
  end

  def self.down
    remove_column :search_sources, :position
  end
end
