class AddIndexForBasketToTopics < ActiveRecord::Migration
  def self.up
    add_column :topics, :index_for_basket_id, :integer, :references => :baskets
    add_column :topic_versions, :index_for_basket_id, :integer, :references => nil
  end

  def self.down
    remove_foreign_key :topics, :index_for_basket_id
    remove_column :topic_versions, :index_for_basket_id
    remove_column :topics, :index_for_basket_id
  end
end
