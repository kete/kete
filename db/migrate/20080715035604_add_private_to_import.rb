class AddPrivateToImport < ActiveRecord::Migration
  def self.up
    add_column :imports, :private, :boolean
  end

  def self.down
    remove_column :imports, :private
  end
end
