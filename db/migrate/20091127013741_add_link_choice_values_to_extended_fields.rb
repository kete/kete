class AddLinkChoiceValuesToExtendedFields < ActiveRecord::Migration
  def self.up
    add_column :extended_fields, :link_choice_values, :boolean
  end

  def self.down
    remove_column :extended_fields, :link_choice_values
  end
end
