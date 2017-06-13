ActiveScaffold.set_defaults do |config| 
  config.ignore_columns.add [:created_at, :updated_at, :lock_version]
end
