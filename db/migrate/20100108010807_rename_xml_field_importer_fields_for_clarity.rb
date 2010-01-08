class RenameXmlFieldImporterFieldsForClarity < ActiveRecord::Migration
  def self.up
    rename_column :imports, :related_records_xml_field, :related_topics_reference_in_record_xml_field
    rename_column :imports, :record_identifier_extended_field_id, :extended_field_that_contains_record_identifier_id
  end

  def self.down
    rename_column :imports, :related_topics_reference_in_record_xml_field, :related_records_xml_field
    rename_column :imports, :extended_field_that_contains_record_identifier_id, :record_identifier_extended_field_id
  end
end
