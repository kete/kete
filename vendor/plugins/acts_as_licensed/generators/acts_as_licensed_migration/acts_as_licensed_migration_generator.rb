class ActsAsLicensedMigrationGenerator < Rails::Generator::NamedBase
    attr_reader :migration_table_name
    def initialize(runtime_args, runtime_options = {})
      @migration_table_name = 'licenses'.tableize
      runtime_args << 'add_licenses_table' if runtime_args.empty?
      super
    end

    def manifest
      record do |m|
        m.migration_template 'migration.rb', 'db/migrate'
      end
    end
  end
