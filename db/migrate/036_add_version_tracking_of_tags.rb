class AddVersionTrackingOfTags < ActiveRecord::Migration
  def self.up
    # so we can revert to a previous version's tags
    ZOOM_CLASSES.each do |zoom_class|
      add_column zoom_class.tableize.to_sym, :raw_tag_list, :string
      add_column "#{zoom_class.tableize.singularize}_versions".to_sym, :raw_tag_list, :string
      # give context to an edit or reverting of version
      add_column zoom_class.tableize.to_sym, :version_comment, :string
      add_column "#{zoom_class.tableize.singularize}_versions".to_sym, :version_comment, :string
    end
  end

  def self.down
    ZOOM_CLASSES.each do |zoom_class|
      remove_column "#{zoom_class.tableize.singularize}_versions".to_sym, :version_comment
      remove_column zoom_class.tableize.to_sym, :version_comment
      remove_column "#{zoom_class.tableize.singularize}_versions".to_sym, :raw_tag_list
      remove_column zoom_class.tableize.to_sym, :raw_tag_list
    end
  end
end
