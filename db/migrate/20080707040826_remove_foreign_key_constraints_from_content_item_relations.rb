class RemoveForeignKeyConstraintsFromContentItemRelations < ActiveRecord::Migration
  def self.up
    if mysql?
      remove_foreign_key_constraint 'content_item_relations', 'content_item_relations_ibfk_1'
      remove_foreign_key_constraint 'deleted_content_item_relations', 'deleted_content_item_relations_ibfk_1'
    elsif postgres?
      remove_foreign_key_constraint 'content_item_relations', 'content_item_relations_pkey'
      remove_foreign_key_constraint 'deleted_content_item_relations', 'deleted_content_item_relations_pkey'
    end
  end

  def self.down
    raise 'This migration is has been commented out by rabid. Edit it to re-enable if you reed it'
    # add_foreign_key_constraint "content_item_relations", "content_item_relations_ibfk_1", "topics"
    # add_foreign_key_constraint "deleted_content_item_relations", "deleted_content_item_relations_ibfk_1", "topics"
  end

  class << self

    def add_foreign_key_constraint(table_name, symbol, foreign_table, foreign_primary_key = 'id')

      if postgres?
        execute(postgres_add_fk_statement(table_name, symbol, foreign_table, foreign_primary_key))
      elsif mysql?
        execute(mysql_add_fk_statement(table_name, symbol, foreign_table, foreign_primary_key))
      else
        raise "Could not run this migration because I couldn't identify the database adapter in use"
      end

      puts "Adding foreign key constraint with key \"#{symbol}\" on column #{foreign_table}_#{foreign_primary_key}."
    end

    def remove_foreign_key_constraint(table_name, symbol)
      if postgres?
        execute(postgres_remove_fk_statement(table_name, symbol))
      elsif mysql?
        execute(mysql_remove_fk_statement(table_name, symbol))
      else
        raise "Could not run this migration because I couldn't identify the database adapter in use"
      end

      puts "Removing foreign key constraint with key \"#{symbol}\"."
    end

    def mysql_remove_fk_statement(table_name, symbol)
      "ALTER TABLE #{table_name} DROP FOREIGN KEY #{symbol}"
    end

    def postgres_remove_fk_statement(table_name, symbol)
      "ALTER TABLE #{table_name} DROP CONSTRAINT #{symbol}"
    end

    def mysql_add_fk_statement(table_name, symbol, foreign_table, foreign_primary_key)
      "ALTER TABLE #{table_name} ADD CONSTRAINT `#{symbol}` FOREIGN KEY `#{foreign_table.singularize}_#{foreign_primary_key}` (`#{foreign_table.singularize}_#{foreign_primary_key}`) REFERENCES `#{foreign_table}` (`#{foreign_primary_key}`)"
    end

    def postgres_add_fk_statement(table_name, symbol, foreign_table, foreign_primary_key)
      # THIS SYNTAX needs to be fixed before you can run the down migration
      # "ALTER TABLE #{table_name} ADD CONSTRAINT `#{symbol}` FOREIGN KEY `#{foreign_table.singularize}_#{foreign_primary_key}` (`#{foreign_table.singularize}_#{foreign_primary_key}`) REFERENCES `#{foreign_table}` (`#{foreign_primary_key}`)"
    end

    def mysql?
      defined?(ActiveRecord::ConnectionAdapters::MysqlAdapter)
    end

    def postgres?
      defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    end
  end

end
