class AddColumnForFilePrivacy < ActiveRecord::Migration
  def self.up
    rename_column 'documents', 'private', 'file_private'
    add_column    'documents', 'private', :boolean
  end

  def self.down
    remove_column 'documents', 'private'
    rename_column 'documents', 'file_private', 'private'
  end
end
