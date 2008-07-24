# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.1.0' unless defined? RAILS_GEM_VERSION

# Walter McGinnis, 2007-10-18
# moving this up before other things that need it
# acts_as_zoom declarations in models
ZOOM_CLASSES = ['Topic', 'StillImage', 'AudioRecording', 'Video', 'WebLink', 'Document', 'Comment']
ACTIVE_SCAFFOLD_CONTROLLERS = ['extended_fields', 'zoom_dbs', 'system_settings', 'oai_pmh_repository_sets', 'licenses']

# Walter McGinnis, 2007-01-07
# You can override default authorization system constants here.
AUTHORIZATION_MIXIN = "object roles"
#DEFAULT_REDIRECTION_HASH = { :controller => 'account', :action => 'login' }
#STORE_LOCATION_METHOD = :store_return_location

# Walter McGinnis, 2008-07-01
# we go through the unusual step of defining a class in this initializer
# which causes rails to bug out that it can't find the module
# require File.join(File.dirname(__FILE__) + '/initializers/', 'oai_pmh')

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on.
  # They can then be installed with "rake gems:install" on new installations.
  
  # Walter McGinnis, 2008-07-02
  # we currently use a hacked version of oai gem
  # and place it under vendor/gems
  # specifying it here allows this to work
  config.gem "oai"
  
  # Kieran, 2008-07-22
  # specify the specific versions we need to run Kete
  # (currently causes problems, will investigate)
  # lib-xml 0.8.0 causes errors in acts_as_zoom
  #config.gem "libxml-ruby", :version => '< 0.8.0'
  # packet 0.1.8 causes imports to fail silently
  #config.gem "packet", :version => '0.1.7'
  
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "aws-s3", :lib => "aws/s3"

  # Only load the plugins named here, in the order given. By default, all plugins
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
    :session_key => '_kete_session',
    :secret      => 'a05fb67d1237cf87cf04a30a7a141d3c1377ae6db1985f15fefa745684790c320e672bda6d9201eea2013f3936bdf57f834006ab4df473c4590cb79944e12a52'
  }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store
  config.action_controller.session_store = :mem_cache_store
  config.cache_store = :file_store, 'tmp/cache'

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector
  # incremental step towards the proper way of doing this in 2.0
  # should go in a file under config/initializers/
  config.active_record.observers = :user_observer

  # white list html elements here, besides defaults
  config.action_view.sanitized_allowed_tags = 'table', 'tr', 'td', 'tbody', 'th', 'thead', 'tfoot', 'font', 'object', 'param', 'embed'
  config.action_view.sanitized_allowed_attributes = 'id', 'style', 'hspace', 'vspace', 'align', 'dir', 'border', 'cellspacing',  'cellpadding', 'summary', 'bgcolor', 'background', 'bordercolor', 'rowspan', 'valign', 'colspan', 'scope', 'lang', 'face', 'color', 'size', 'target', 'classid', 'codebase', 'quality', 'type', 'pluginspage', 'wmode'

  # we need to set up randmom_finders first
  config.plugins = [ :random_finders, :all ]
end

require File.join(File.dirname(__FILE__), '/../lib/error_handling')

# Include your application configuration below

# Walter McGinnis, 2007-12-03
# most application specific configuration has moved to files
# under config/initializers/
