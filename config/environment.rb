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

  config.action_controller.session_store = :mem_cache_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Walter McGinnis, 2007-07-10
  # TODO: what the deal with depreciated observer in edge and 2.0?
  # ActiveRecord::Base.observers = [:user_observer]

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
    :filename_datetime => "%Y-%m-%d-%H-%M",
    :euro_date => "%d/%m/%Y",
    :euro_date_time => "%d/%m/%Y %H:%M"
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

# poached and modified to include non-gem/lib requirements
# from http://www.depixelate.com/2006/8/9/quick-tip-ensuring-required-gems-and-libs-are-available
# --- [ check that we have all the gems and libs we need ] ---

missing_libs = Array.new
required_software = YAML.load_file("#{RAILS_ROOT}/config/required_software.yml")
required_libs = required_software['gems']
required_software['libs'].each do |key, value|
  required_libs[key] = value
end
required_libs.values.each do |lib|
  begin
    require lib
  rescue LoadError
    missing_libs << lib
  end
end

missing_software = { 'Gems' => missing_libs }

# if standard rails things like mysql aren't installed, the server won't start up
# so they don't need to be done here
missing_commands = Array.new
required_commands = required_software['commands']
required_commands.each do |pretty_name, command|
  command_found = `which #{command}`
  if command_found.blank?
    missing_commands << pretty_name
  end
end

missing_software['Commands'] = missing_commands

MISSING_SOFTWARE = missing_software

# acts_as_zoom declarations in models
ZOOM_CLASSES = ['Topic', 'StillImage', 'AudioRecording', 'Video', 'WebLink', 'Document', 'Comment']

# has to do with use of attachment_fu
BASE_PRIVATE_PATH = 'private'

# if SystemSetting model doesn't exist, set IS_CONFIGURED to falee
begin
  current_migration = (ActiveRecord::Base.connection.select_one("SELECT version FROM schema_info") || {"version" => 0})["version"].to_i
rescue
  current_migration = 0
end

if Object.const_defined?('SystemSetting') and  current_migration > 40
  # make each setting a global constant
  # see reference for Module for more details about constant setting, etc.
  SystemSetting.find(:all).each do |setting|
    value = setting.value
    if !value.blank? and value.match(/^([0-9\{\[]|true|false)/)
      # Serious potential security issue, we eval user inputed value at startup
      # for things that are recognized as boolean, integer, hash, or array
      # by regexp above
      # Make sure only knowledgable and AUTHORIZED people can edit System Settings
      value = eval(setting.value)
    end
    Object.const_set(setting.name.upcase.gsub(/[^A-Z0-9\s_-]+/,'').gsub(/[\s-]+/,'_'), value)
  end

  if !Object.const_defined?('IS_CONFIGURED')
    IS_CONFIGURED = false
  end
else
  IS_CONFIGURED = false

  # we have to load meaningless default values for any constant used in our models
  # since otherwise things like migrations will fail, before we bootstrap the db
  # these will be set up with system settings after rake db:bootstrap
  MAXIMUM_UPLOADED_FILE_SIZE = 50.megabyte
  IMAGE_SIZES = {:small_sq => [50, 50], :small => '50', :medium => '200>', :large => '400>'}
  AUDIO_CONTENT_TYPES = ['audio/mpeg']
  DOCUMENT_CONTENT_TYPES = ['text/html']
  IMAGE_CONTENT_TYPES = [:image]
  VIDEO_CONTENT_TYPES = ['video/mpeg']
  SITE_URL = "kete.net.nz"
  NOTIFIER_EMAIL = "kete@library.org.nz"

end

# Walter McGinnis (walter@katipo.co.nz), 2006-09-26
# include Globalize # put that thing here
# Locale.set_base_language('en-NZ') # and here :)'')

if IS_CONFIGURED
  # Walter McGinnis (walter@katipo.co.nz), 2006-12-06
  # used by the acts_as_zoom plugin
  ZoomDb.zoom_id_stub = "oai:" + SITE_NAME + ":"
  ZoomDb.zoom_id_element_name = "identifier"
  # in case your zoom_id is in a nested element
  # separated by /'s
  # no preceding / necessary
  ZoomDb.zoom_id_xml_path_up_to_element = "record/header"
end

# For handling pre controller errors
# see http://wiki.rubyonrails.org/rails/pages/HandlingPreControllerErrors
require 'error_handler_basic' # defines AC::Base#rescue_action_in_public

# making the attachment_fu upload file error more helpful
ActiveRecord::Errors.default_error_messages[:inclusion] += '.  Are you sure entered the right type of file for what you wanted to upload?  For example, a .jpg for an image.'
