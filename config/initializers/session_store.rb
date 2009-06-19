# key and secret stored in config/session_config.yml
session_config = File.join(RAILS_ROOT, 'config/session_config.yml')
unless File.exists?(session_config)
  raise "config/session_config.yml not present. Please run 'rake kete:tools:regenerate_session_configuration' and try again."
end
session_config = YAML.load(IO.read(session_config))['session']

ActionController::Base.session = {
  :key         => session_config['key'],
  :secret      => session_config['secret']
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
