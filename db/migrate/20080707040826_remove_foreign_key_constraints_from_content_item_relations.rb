class RemoveForeignKeyConstraintsFromContentItemRelations < ActiveRecord::Migration
  def self.up
    # foreign_key_migrations does not appear to support removing foreign key constaints 
    # without completely recreating the column, which we need to avoid. So, as a work 
    # around, we're doing to remove the foreign keys by hand.
    
    remove_foreign_key_constraint "content_item_relations", "content_item_relations_ibfk_1"
    remove_foreign_key_constraint "deleted_content_item_relations", "deleted_content_item_relations_ibfk_1"
  end

  def self.down
    add_foreign_key_constraint "content_item_relations", "content_item_relations_ibfk_1", "topics"
    add_foreign_key_constraint "deleted_content_item_relations", "deleted_content_item_relations_ibfk_1", "topics"
  end
  
  class << self
  
    def add_foreign_key_constraint(table_name, symbol, foreign_table, foreign_primary_key = "id")
      execute("ALTER TABLE #{table_name} ADD CONSTRAINT `#{symbol}` FOREIGN KEY `#{foreign_table.singularize}_#{foreign_primary_key}` (`#{foreign_table.singularize}_#{foreign_primary_key}`) REFERENCES `#{foreign_table}` (`#{foreign_primary_key}`)")
      print "Adding foreign key constraint with key \"#{symbol}\" on column #{foreign_table}_#{foreign_primary_key}.\n"
    end
  
    def remove_foreign_key_constraint(table_name, symbol)
      execute("ALTER TABLE #{table_name} DROP FOREIGN KEY #{symbol}")
      print "Removing foreign key constraint with key \"#{symbol}\".\n"
    end

  end
    
end
