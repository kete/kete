class AddDefaultBasket < ActiveRecord::Migration
  def self.up
    # we now rely on bootstrapping for this step
    # Basket.create(:name => 'Site', :urlified_name => 'site')
  end

  def self.down
    # this will be destroyed when we toss baskets table
    # Basket.find(1).destroy
  end
end
