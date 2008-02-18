# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.5'

# Walter McGinnis, 2007-10-18
# moving this up before other things that need it
# acts_as_zoom declarations in models
ZOOM_CLASSES = ['Topic', 'StillImage', 'AudioRecording', 'Video', 'WebLink', 'Document', 'Comment']

# Walter McGinnis, 2007-01-07
# You can override default authorization system constants here.
AUTHORIZATION_MIXIN = "object roles"
#DEFAULT_REDIRECTION_HASH = { :controller => 'account', :action => 'login' }
#STORE_LOCATION_METHOD = :store_return_location

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  config.action_controller.session_store = :mem_cache_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # See Rails::Configuration for more options

  # Walter McGinnis, 2007-10-18
  # incremental step towards the proper way of doing this in 2.0
  # should go in a file under config/initializers/
  config.active_record.observers = :user_observer

  # white list html elements here, besides defaults
  config.action_view.sanitized_allowed_tags = 'table', 'tr', 'td', 'tbody', 'th', 'thead', 'tfoot', 'font'
  config.action_view.sanitized_allowed_attributes = 'id', 'style', 'hspace', 'vspace', 'align', 'dir', 'border', 'cellspacing',  'cellpadding', 'summary', 'bgcolor', 'background', 'bordercolor', 'rowspan', 'valign', 'colspan', 'scope', 'lang', 'face', 'color', 'size', 'target'

  # we need to set up randmom_finders first
  config.plugins = [ :random_finders, :all ]
end

# Include your application configuration below

# Walter McGinnis, 2007-12-03
# most application specific configuration has moved to files
# under config/initializers/

