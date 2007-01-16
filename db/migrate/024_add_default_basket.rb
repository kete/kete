class AddDefaultBasket < ActiveRecord::Migration
  def self.up
    Basket.create(:name => 'Site', :urlified_name => 'site')
  end

  def self.down
    basket = Basket.find_by_id(1)
    # work around versioning
    ZOOM_CLASSES.each do |zoom_class|
      Module.class_eval(zoom_class).drop_versioned_table
    end
    basket.destroy
  end
end
