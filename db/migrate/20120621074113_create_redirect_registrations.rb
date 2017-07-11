class CreateRedirectRegistrations < ActiveRecord::Migration
  def self.up
    create_table :redirect_registrations do |t|
      t.text :source_url_pattern, :target_url_pattern, null: false
      t.integer :status_code, null: false, default: 301

      t.timestamps
    end
  end

  def self.down
    drop_table :redirect_registrations
  end
end
