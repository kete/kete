class AddParentIdToImages < ActiveRecord::Migration
  def self.up
    # foreing_key_migrations auto constraint building
    # parent_id in this case, is self-referential
    add_column :images, :parent_id, :integer, :references => :images
    add_column :image_versions, :parent_id, :integer, :references => nil
  end

  def self.down
    remove_column :images, :parent_id
    remove_column :image_versions, :parent_id
  end
end
