class CreateOaiPmhRepositorySets < ActiveRecord::Migration
  def self.up
    create_table :oai_pmh_repository_sets do |t|
      t.references :zoom_db
      t.string :name, :set_spec, :match_code, :value, null: false
      t.string :description
      t.boolean :active, default: true
      t.boolean :dynamic, default: false
      t.timestamps
    end
  end

  def self.down
    drop_table :oai_pmh_repository_sets
  end
end
