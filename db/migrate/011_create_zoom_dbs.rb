class CreateZoomDbs < ActiveRecord::Migration
  def self.up
    create_table :zoom_dbs do |t|
      t.column :database_name, :string, null: false
      t.column :description, :text
      t.column :host, :string, null: false
      t.column :port, :text, null: false
      t.column :zoom_user, :string
      t.column :zoom_password, :string
      t.column :created_at, :datetime, null: false
      t.column :updated_at, :datetime, null: false
    end
  end

  def self.down
    drop_table :zoom_dbs
  end
end
