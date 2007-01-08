class AddDefaultBasket < ActiveRecord::Migration
  def self.up
    Basket.create(:name => 'Default', :urlified_name => 'default')
  end

  def self.down
    ImageFile.delete_all
    StillImage.delete_all
    Video.delete_all
    AudioRecording.delete_all
    WebLink.delete_all
    Topic.delete_all
    Basket.delete_all
  end
end
