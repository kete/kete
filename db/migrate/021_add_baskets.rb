class AddBaskets < ActiveRecord::Migration
  def self.up
    create_table :baskets do |t|
      t.column :name, :string, :null => false
      t.column :urlified_name, :string
    end
  end

  def self.down
    drop_table :baskets
  end
end
