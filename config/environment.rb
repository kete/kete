# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Walter McGinnis (walter@katipo.co.nz), 2007-01-07
# You can override default authorization system constants here.
AUTHORIZATION_MIXIN = "object roles"
#DEFAULT_REDIRECTION_HASH = { :controller => 'account', :action => 'login' }
#STORE_LOCATION_METHOD = :store_return_location

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.1.6'

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

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # See Rails::Configuration for more options
end

# date styles:
ActiveSupport::CoreExtensions::Time::Conversions::DATE_FORMATS.merge!(
    :date => "%Y-%m-%d",
    :presentable_datetime => "%a %b %d, %Y %H:%M",
    :euro_date => "%d/%m/%Y"
)

# Add new inflection rules using the following format
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Include your application configuration below

# Walter McGinnis (walter@katipo.co.nz), 2006-09-26
# include Globalize # put that thing here
# Locale.set_base_language('en-NZ') # and here :)'')

# Walter McGinnis (walter@katipo.co.nz), 2006-12-06
# used by the acts_as_zoom plugin
ZoomDb.zoom_id_stub = "oai:casanova.katipo.co.nz:"
ZoomDb.zoom_id_element_name = "identifier"
# in case your zoom_id is in a nested element
# separated by /'s
# no preceding / necessary
ZoomDb.zoom_id_xml_path_up_to_element = "record/header"

# used in acts_as_zoom to replace missing object id
# at the time it works through oai_record.xml output
# during after_save callback
ID_SUB = '!!!ID!!!'

DEFAULT_RECORDS_PER_PAGE = 5
RECORDS_PER_PAGE_CHOICES = [5, 10, 20, 50]
DEFAULT_SEARCH_CLASS = 'Topic'

# TODO: make this dynamic if possible
# from acts_as_zoom declarations in models
ZOOM_CLASSES = ['Topic', 'StillImage', 'AudioRecording', 'Video', 'WebLink', 'Document']

# has to do with use of attachment_fu
BASE_PRIVATE_PATH = 'private'

# how many related items or topics to display
NUMBER_OF_RELATED_THINGS_TO_DISPLAY_PER_TYPE = 5
NUMBER_OF_RELATED_IMAGES_TO_DISPLAY = 5
DEFAULT_NUMBER_OF_MULTIPLES = 5
