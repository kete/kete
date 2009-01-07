@auth_credentials_file = File.join(RAILS_ROOT, 'config/site_lockdown_auth_credentials.yml')
if File.exists?(@auth_credentials_file)
  @auth_credentials = YAML.load(IO.read(@auth_credentials_file))
  USERNAME = @auth_credentials[:username] || @auth_credentials['username']
  PASSWORD = @auth_credentials[:password] || @auth_credentials['password']
end
