class CreateConfigurableSettings < ActiveRecord::Migration
  def self.up
    ConfigurableSetting.create_table
  end

  def self.down
    ConfigurableSetting.drop_table
  end
end
