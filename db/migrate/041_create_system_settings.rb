class CreateSystemSettings < ActiveRecord::Migration
  # Walter McGinnis, 2007-07-12
  # adding a section attribute to the plugins defaults
  # allowing null value
  def self.up
    create_table :system_settings do |t|
      t.column :name, :string, :null => false, :limit => 255
      t.column :section, :string, :null => false, :limit => 255
      t.column :explanation, :text
      t.column :value,  :text
      t.column :technically_advanced, :boolean, :default => false
      t.column :required_to_be_configured, :boolean, :default => false
    end

    add_index :system_settings, [:name], :unique => true
  end

  def self.down
    drop_table :system_settings
  end
end
