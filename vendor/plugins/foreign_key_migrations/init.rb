ActiveRecord::Base.send(:include, RedHillConsulting::ForeignKeyMigrations::ActiveRecord::Base)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, RedHillConsulting::ForeignKeyMigrations::ActiveRecord::ConnectionAdapters::AbstractAdapter)
ActiveRecord::ConnectionAdapters::TableDefinition.send(:include, RedHillConsulting::ForeignKeyMigrations::ActiveRecord::ConnectionAdapters::TableDefinition)
