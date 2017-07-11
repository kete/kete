# This migration comes from acts_as_taggable_on_engine (originally 1)
# It has been modified for Kete Horowhenau because we are upgrading from 1.0
# (not starting from scratch)
class ActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up
    add_index :taggings, %i[taggable_id taggable_type context]
  end

  def self.down
    remove_index :taggings, %i[taggable_id taggable_type context]
  end
end
