# Load the rails application
require File.expand_path('../application', __FILE__)

# Walter McGinnis, 2010-05-08
# For holding info about the kete application instance
# require File.join(File.dirname(__FILE__), '../lib/kete')

# Walter McGinnis, 2007-10-18
# moving this up before other things that need it
# acts_as_zoom declarations in models
ITEM_CLASSES = %w(Topic StillImage AudioRecording Video WebLink Document)
ZOOM_CLASSES = ITEM_CLASSES + ['Comment']
# items that may have attached file(s)
ATTACHABLE_CLASSES = ITEM_CLASSES - %w(WebLink Topic)
ACTIVE_SCAFFOLD_CONTROLLERS = ['extended_fields', 'zoom_dbs', 'system_settings', 'oai_pmh_repository_sets', 'licenses', 'choices', 'search_sources', 'profiles']
CACHES_CONTROLLERS = ['audio', 'baskets', 'comments', 'documents', 'images', 'topics', 'video', 'web_links']

# Walter McGinnis, 2007-01-07
# You can override default authorization system constants here.
# AUTHORIZATION_MIXIN = "object roles"
# DEFAULT_REDIRECTION_HASH = { :controller => 'account', :action => 'login' }
# STORE_LOCATION_METHOD = :store_return_location

# Walter McGinnis, 2008-07-01
# we go through the unusual step of defining a class in this initializer
# which causes rails to bug out that it can't find the module
# require File.join(File.dirname(__FILE__) + '/initializers/', 'oai_pmh')

# Bootstrap the Rails environment, frameworks, and default configuration
# require File.join(File.dirname(__FILE__), 'boot')

# !! Fixing rubygems vs rake error: undefined local variable or method `version_requirements'
# if Gem::VERSION >= "1.3.6"
#   module Rails
#     class GemDependency
#
#       def requirement
#         r = super
#         (r == Gem::Requirement.default) ? nil : r
#       end
#     end
#   end
# end

# Rails::Initializer.run do |config|
#  # Settings in config/environments/* take precedence over those specified here.
#  # Application configuration should go into files in config/initializers
#  # -- all .rb files in that directory are automatically loaded.
#
#  # Add additional load paths for your own custom dirs
#  # config.load_paths += %W( #{RAILS_ROOT}/extras )
#
#  # Specify gems that this application depends on and have them installed with rake gems:install
#  # config.gem "bj"
#  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
#  # config.gem "sqlite3-ruby", :lib => "sqlite3"
#  # config.gem "aws-s3", :lib => "aws/s3"
#
#  # Walter McGinnis, 2008-07-02
#  # we currently use a hacked version of oai gem
#  # and place it under vendor/gems
#  # specifying it here allows this to work
#  config.gem "oai"
#
#  # Walter McGinnis, 2011-02-15
#  # because this is a Rails engine gem
#  # it needs to be declared here as well as config/required_software.rb
#  config.gem "oembed_provider"
#
#  config.gem "tiny_mce"
#  config.gem "tiny_mce_plugin_imageselector"
#
#  config.gem "gmaps4rails"
#
#  # Only load the plugins named here, in the order given (default is alphabetical).
#  # :all can be used as a placeholder for all plugins not explicitly named
#  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
#  config.plugins = [ :random_finders, :all ]
#
#  # Skip frameworks you're not going to use. To use Rails without a database,
#  # you must remove the Active Record framework.
#  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]
#
#  # Activate observers that should always be running
#  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer
#  config.active_record.observers = :user_observer
#
#  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
#  # Run "rake -D time" for a list of tasks for finding time zone names.
#  config.time_zone = 'UTC'
#
#  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
#  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
#  # config.i18n.default_locale = :de
#
#  # Use the database for sessions instead of the cookie-based default,
#  # which shouldn't be used to store highly confidential information
#  # (create the session table with "rake db:sessions:create")
#  # config.action_controller.session_store = :active_record_store
#  config.action_controller.session_store = :mem_cache_store
#  config.cache_store = :file_store, 'tmp/cache'
#
#  # white list html elements here, besides defaults
#  config.action_view.sanitized_allowed_tags = 'table', 'tr', 'td', 'tbody', 'th', 'thead', 'tfoot', 'font', 'object', 'param', 'embed'
#  config.action_view.sanitized_allowed_attributes = 'id', 'style', 'hspace', 'vspace', 'align', 'dir', 'border', 'cellspacing',  'cellpadding', 'summary', 'bgcolor', 'background', 'bordercolor', 'rowspan', 'valign', 'colspan', 'scope', 'lang', 'face', 'color', 'size', 'target', 'classid', 'codebase', 'quality', 'type', 'pluginspage', 'wmode', 'data', 'flashvars', 'allowfullscreen'
# end
#
## Walter McGinnis, 2009-09-08
## rolling this back, as Nokogiri may not work with Extended Fields populating
## more research necessary, may use LibXML if it is compatible
## ActiveSupport::XmlMini.backend = 'Nokogiri'
#
## Include your application configuration below
#
## Walter McGinnis, 2007-12-03
## most application specific configuration has moved to files
## under config/initializers/
#
## Walter McGinnis, 2011-07-28
## put our locales last, so our application's declarations take precedence
# I18n.load_path += Dir[ Rails.root.join('config', 'locales', '*.{rb,yml}') ]
## TODO: we could do some deleting of existing load_path entries to speed up reload in future
# I18n.reload! # by this point previous load_path's values were already loaded
#
## Load application extensions that have been registered by add-ons
# Kete.setup_extensions!

# Initialize the rails application
KeteApp::Application.initialize!
