class RemoveForeignKeyConstraintsFromContentItemRelations < ActiveRecord::Migration
  def self.up
    # we're rolling our own here because we have had some problems with
    # foreign_key_migrations support of removing foreign key constaints
    # IMPORTANT: it should be noted that there are some assumptions here about the constraint name
    # and that this may not work with PostgreSQL or other RDBMSs, please feel free to submit patches!
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
