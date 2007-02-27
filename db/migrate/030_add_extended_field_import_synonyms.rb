class AddExtendedFieldImportSynonyms < ActiveRecord::Migration
  def self.up
    # comma separated list of field names
    # that map to this field when importing
    add_column :extended_fields, :import_synonyms, :text
  end

  def self.down
    remove_column :extended_fields, :import_synonyms
  end
end
