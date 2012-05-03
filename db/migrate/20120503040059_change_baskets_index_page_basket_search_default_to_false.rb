class ChangeBasketsIndexPageBasketSearchDefaultToFalse < ActiveRecord::Migration
  def self.up
    change_column_default(:baskets, :index_page_basket_search, false)
  end

  def self.down
    change_column_default(:baskets, :index_page_basket_search, true)
  end
end
