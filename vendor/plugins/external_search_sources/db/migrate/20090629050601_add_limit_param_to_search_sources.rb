class AddLimitParamToSearchSources < ActiveRecord::Migration
  def self.up
    add_column :search_sources, :limit_param, :string
  end

  def self.down
    remove_column :search_sources, :limit_param
  end
end
