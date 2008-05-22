class AddShowPrivacyControlsToBaskets < ActiveRecord::Migration
  def self.up
    add_column 'baskets', 'show_privacy_controls', :boolean
  end

  def self.down
    remove_column 'baskets', 'show_privacy_controls'
  end
end
