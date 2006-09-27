class CreateTopicTypes < ActiveRecord::Migration
  def self.up
    create_table :topic_types do |t|
      t.column :name, :string
      t.column :description, :text
      t.column :xml_specification, :text
    end
  end

  def self.down
    drop_table :topic_types
  end
end
