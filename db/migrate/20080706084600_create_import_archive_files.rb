class CreateImportArchiveFiles < ActiveRecord::Migration
  def self.up
    create_table :import_archive_files do |t|
      t.string :filename, :content_type
      t.integer :size, :import_id
      t.integer :parent_id, :references => nil
      t.timestamps
    end
  end

  def self.down
    drop_table :import_archive_files
  end
end
