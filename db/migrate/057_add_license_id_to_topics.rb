class AddLicenseIdToTopics < ActiveRecord::Migration
  def self.up
    add_column 'topics', 'license_id', :integer
  end

  def self.down
    remove_column 'topics', 'license_id'
  end
end
