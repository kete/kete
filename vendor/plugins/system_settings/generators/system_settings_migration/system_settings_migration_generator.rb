class SystemSettingsMigrationGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options = {})
    runtime_args << 'create_system_settings' if runtime_args.empty?
    super
  end

  def manifest
    record do |m|
      m.migration_template 'migration.rb', 'db/migrate'
    end
  end
end
