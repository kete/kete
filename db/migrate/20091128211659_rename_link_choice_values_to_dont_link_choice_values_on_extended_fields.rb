class RenameLinkChoiceValuesToDontLinkChoiceValuesOnExtendedFields < ActiveRecord::Migration
  def self.up
    rename_column :extended_fields, :link_choice_values, :dont_link_choice_values
  end

  def self.down
    rename_column :extended_fields, :dont_link_choice_values, :link_choice_values
  end
end
