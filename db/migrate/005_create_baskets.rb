class CreateBaskets < ActiveRecord::Migration
  def self.up
    create_table :baskets do |t|
      t.column :name, :string, null: false
      t.column :urlified_name, :string
      t.column :extended_content, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end

  def self.down
    drop_table :baskets
  end
end
