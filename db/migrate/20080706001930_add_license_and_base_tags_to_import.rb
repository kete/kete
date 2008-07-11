# base tags are added to every item imported
class AddLicenseAndBaseTagsToImport < ActiveRecord::Migration
  def self.up
    change_table :imports do |t|
      t.string :base_tags
      t.integer :license_id, :references => nil
    end
  end

  def self.down
    change_table :imports do |t|
      t.remove :base_tags, :license_id
    end
  end
end
