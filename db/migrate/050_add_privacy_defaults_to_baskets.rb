class AddPrivacyDefaultsToBaskets < ActiveRecord::Migration
  def self.up
    # Add privacy defaults columns
    add_column 'baskets', 'private_default', :boolean
    add_column 'baskets', 'file_private_default', :boolean
  end

  def self.down
    # Remove privacy defaults columns
    remove_column 'baskets', 'private_default'
    remove_column 'baskets', 'file_private_default'
  end
end
