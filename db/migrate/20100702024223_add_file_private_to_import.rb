class AddFilePrivateToImport < ActiveRecord::Migration
  def self.up
    change_table :imports do |t|
      t.boolean :file_private, default: false
    end
  end

  def self.down
    change_table :imports do |t|
      t.remove :file_private
    end
  end
end
