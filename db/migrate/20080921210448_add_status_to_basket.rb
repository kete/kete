class AddStatusToBasket < ActiveRecord::Migration
  def self.up
    add_column :baskets, :status, :string
    add_column :baskets, :creator_id, :integer, :references => nil
  end

  def self.down
    remove_column :baskets, :status
    remove_column :baskets, :creator_id
  end
end
