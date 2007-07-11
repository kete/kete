<%
  table_name = "system_setting"
  table_name = table_name.pluralize if ActiveRecord::Base.pluralize_table_names
-%>
class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
      t.column :name,   :string,  :null => false, :limit => 255
      t.column :value,  :text,    :null => false
    end

    add_index :<%= table_name %>, [:name], :unique => true
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
