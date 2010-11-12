class AddAnonymousFieldsToContributions < ActiveRecord::Migration
  def self.up
    change_table :contributions do |t|
      t.text :email_for_anonymous
      t.text :name_for_anonymous
      t.text :website_for_anonymous
    end
  end

  def self.down
    change_table :contributions do |t|
      t.remove :email_for_anonymous
      t.remove :name_for_anonymous
      t.remove :website_for_anonymous
    end
  end
end
