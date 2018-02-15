# Topic already has it's own migration.
# Add related_items_position to everything else (except Comments)
class AddRelatedItemPositionFieldsToItems < ActiveRecord::Migration
  def self.up
    (ZOOM_CLASSES - %w[Topic Comment]).each do |zoom_class|
      add_column zoom_class.tableize.to_sym, :related_items_position, :text
      add_column "#{zoom_class.tableize.singularize}_versions".to_sym, :related_items_position, :text
    end
  end

  def self.down
    (ZOOM_CLASSES - %w[Topic Comment]).each do |zoom_class|
      remove_column zoom_class.tableize.to_sym, :related_items_position
      remove_column "#{zoom_class.tableize.singularize}_versions".to_sym, :related_items_position
    end
  end
end
