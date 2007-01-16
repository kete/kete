class CreateContributions < ActiveRecord::Migration
  def self.up
    create_table :contributions do |t|
    end
  end

  def self.down
    drop_table :contributions
  end
end
