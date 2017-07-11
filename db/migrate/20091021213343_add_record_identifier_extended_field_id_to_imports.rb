class AddRecordIdentifierExtendedFieldIdToImports < ActiveRecord::Migration
  def self.up
    add_column :imports, :record_identifier_extended_field_id, :integer, references: nil
  end

  def self.down
    remove_column :imports, :record_identifier_extended_field_id
  end
end
