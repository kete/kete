class DropSystemSettings < ActiveRecord::Migration
  def self.up
    drop_table :system_settings
  end

  def self.down
    puts 'Sorry you will have to recreate the system_settings table manually if you want it back'
  end
end
