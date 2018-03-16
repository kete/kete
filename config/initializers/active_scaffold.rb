# frozen_string_literal: true

ActiveScaffold.set_defaults do |config|
  config.ignore_columns.add %i[created_at updated_at lock_version]
end
