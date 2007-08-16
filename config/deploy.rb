set :application, "set your application name here"
set :repository,  "set your repository location here"

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/home/kete/apps/#{application}"

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

role :app, "your app-server here"
role :web, "your web-server here"
role :db,  "your db-server here", :primary => true

set :user, "kete"

# set :config_files, %w(database.yml)

# keeps a svn working copy locally under shared/cached-copy
# rather than do a full svn checkout each deploy:update_code
# it does a svn update in cached_copy and then copies to the release directory
# much faster on subsequent deploys than :deploy_via, :checkout
set :deploy_via, :remote_cache

# =============================================================
# Mongrel Settings (assumes Debian for config file location)
# =============================================================
set :mongrel_servers, 1
set :mongrel_port, 8000
set :mongrel_environment, 'production'
set :mongrel_address, '127.0.0.1'
set :mongrel_conf, "/etc/mongrel_cluster/#{application}.yml"

