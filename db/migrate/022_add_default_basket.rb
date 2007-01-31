class AddDefaultBasket < ActiveRecord::Migration
  def self.up
    Basket.create(:name => 'Site', :urlified_name => 'site')
  end

  def self.down
    Basket.find(1).destroy
  end
end
