class AddAllowEmailsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :allow_emails, :boolean
  end

  def self.down
    remove_column :users, :allow_emails
  end
end
