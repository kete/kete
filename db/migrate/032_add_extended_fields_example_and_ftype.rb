class AddExtendedFieldsExampleAndFtype < ActiveRecord::Migration
  def self.up
    add_column :extended_fields, :example, :string, limit: 255
    add_column :extended_fields, :ftype,   :string, limit: 10, default: 'text'
  end

  def self.down
    remove_column :extended_fields, :example
    remove_column :extended_fields, :ftype    
  end
end
