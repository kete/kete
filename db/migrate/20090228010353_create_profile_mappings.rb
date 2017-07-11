class CreateProfileMappings < ActiveRecord::Migration
  def self.up
    create_table :profile_mappings do |t|
      t.belongs_to :profile, null: false
      t.belongs_to :profilable, polymorphic: { default: 'Basket' }, null: false, references: nil

      t.timestamps
    end
  end

  def self.down
    drop_table :profile_mappings
  end
end
