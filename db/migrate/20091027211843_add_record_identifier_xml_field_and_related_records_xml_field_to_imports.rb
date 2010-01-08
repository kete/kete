class AddRecordIdentifierXmlFieldAndRelatedRecordsXmlFieldToImports < ActiveRecord::Migration
  def self.up
    add_column :imports, :record_identifier_xml_field, :string
    add_column :imports, :related_records_xml_field, :string
  end

  def self.down
    remove_column :imports, :related_records_xml_field
    remove_column :imports, :record_identifier_xml_field
  end
end
