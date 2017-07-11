class CreateImports < ActiveRecord::Migration
  def self.up
    create_table :imports do |t|
      t.text :status
      t.integer :records_processed
      t.integer :interval_between_records, null: false
      t.text :default_description_end_template
      t.text :description_beginning_template
      t.text :xml_type, null: false
      t.text :xml_path_to_record
      t.text :directory, null: false
      t.integer :topic_type_id, null: false
      t.integer :basket_id, null: false
      t.integer :user_id, null: false
      t.timestamps
    end
  end

  def self.down
    drop_table :imports
  end
end
