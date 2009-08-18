class AddBasketIdToTaggings < ActiveRecord::Migration
  def self.up
    add_column :taggings, :basket_id, :integer
  end

  def self.down
    remove_column :taggings, :basket_id
  end
end
