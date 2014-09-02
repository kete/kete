class AddTaggerReferenceToTaggings < ActiveRecord::Migration
  def self.up
    add_column :taggings, :tagger_id, :integer
    add_column :taggings, :tagger_type, :string
  end

  def self.down
    remove_column :taggings, :tagger_id
    remove_column :taggings, :tagger_type
  end
end
