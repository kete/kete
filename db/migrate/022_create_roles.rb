class CreateRoles < ActiveRecord::Migration
  def self.up
    create_table :roles_users, :id => false, :force => true  do |t|
      t.column :user_id,          :integer
      t.column :role_id,          :integer
      t.column :created_at,       :datetime
      t.column :updated_at,       :datetime
    end

    create_table :roles, :force => true do |t|
      t.column :name,               :string, :limit => 40
      t.column :authorizable_type,  :string, :limit => 30
      t.column :authorizable_id,    :integer
      t.column :created_at,         :datetime
      t.column :updated_at,         :datetime
    end
  end

  def self.down
    drop_table :roles
    drop_table :roles_users
  end
end
