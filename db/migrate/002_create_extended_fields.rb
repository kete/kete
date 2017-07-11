class CreateExtendedFields < ActiveRecord::Migration
  def self.up
    create_table :extended_fields do |t|
      t.column :label, :string, null: false
      t.column :xml_element_name, :string
      t.column :xsi_type, :string
      t.column :multiple, :boolean, default: false
      t.column :description, :text
      t.column :created_at, :datetime, null: false
      t.column :updated_at, :datetime, null: false
    end
  end

  def self.down
    drop_table :extended_fields
  end
end
