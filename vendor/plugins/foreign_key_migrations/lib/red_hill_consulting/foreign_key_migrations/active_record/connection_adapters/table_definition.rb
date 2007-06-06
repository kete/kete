module RedHillConsulting::ForeignKeyMigrations::ActiveRecord::ConnectionAdapters
  module TableDefinition
    def self.included(base)
      base.class_eval do
        alias_method_chain :column, :foreign_key_migrations
      end
    end

    def column_with_foreign_key_migrations(name, type, options = {})
      column_without_foreign_key_migrations(name, type, options)
      references_table_name = ActiveRecord::Base.references_table_name(name, options)
      foreign_key(name, references_table_name, :id, options) if references_table_name
      self
    end

    # Some people liked this; personally I've decided against using it but I'll keep it nonetheless
    def belongs_to(table, options = {})
      options = options.merge(:references => table)
      options[:on_delete] = options.delete(:dependent) if options.has_key?(:dependent)
      column("#{table.to_s.singularize}_id".to_sym, :integer, options)
    end
  end
end
