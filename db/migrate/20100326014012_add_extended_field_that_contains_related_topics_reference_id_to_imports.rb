class AddExtendedFieldThatContainsRelatedTopicsReferenceIdToImports < ActiveRecord::Migration
  def self.up
    add_column :imports, :extended_field_that_contains_related_topics_reference_id, :integer, references: nil
  end

  def self.down
    remove_column :imports, :extended_field_that_contains_related_topics_reference_id
  end
end
