class AddDefaultLicenseIdToUsers < ActiveRecord::Migration
  def self.up
    add_column 'users', 'license_id', :integer
  end

  def self.down
    remove_column 'users', 'license_id'
  end
end
