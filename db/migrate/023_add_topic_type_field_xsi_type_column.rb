class AddTopicTypeFieldXsiTypeColumn < ActiveRecord::Migration
  def self.up
    add_column :topic_type_fields, :xsi_type, :string
  end

  def self.down
    remove_column :topic_type_fields, :xsi_type
  end
end
