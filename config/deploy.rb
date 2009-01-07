# support multi-stage deployment
# (requires capistrano-ext gem)
# require 'capistrano/ext/multistage'

# support for ruby defined application configurations
# (requires capistrano-configuration)
# require 'capistrano-configuration'

# What is your application called and where are you getting it from?
set :application, "set your application name here"
set :repository,  "set your repository location here"

# Where are your deployed applications?
# change this if you deploy to a different directory
# than what we outline in Kete installation guide
set :path_to_apps, "/home/kete/apps"

# Where on the server should this application reside?
set :deploy_to, "#{path_to_apps}/#{application}"

# If you aren't using Git to manage your source code
# change :git to the prefered SCM system (:subversion)
# Example
# set :scm, :subversion
set :scm, :git
set :branch, "master"
set :scm_username, "username"
set :scm_password, "password"

# Which user/group on the server will be running the application?
set :user, "kete"
set :group, "kete"

# Which server should we deploy to?
role :app, "your app-server here"
role :web, "your web-server here"
role :db,  "your db-server here", :primary => true

set :config_files, []

# keeps a checked out/cloned copy of the site on the deployed server so next time
# it updates the codebase, instead of redownloading the whole app (faster this way)
set :deploy_via, :remote_cache

# Uncomment and configure the rest if you use Mongrel, otherwise, if you use Apache
# these settings won't apply to you

# ======================================================================
# Mongrel Settings (assumes Linux distribution for config file location)
# ======================================================================
#set :mongrel_servers, 1
#set :mongrel_port, 8000
#set :mongrel_environment, 'production'
#set :mongrel_address, '127.0.0.1'
#set :mongrel_conf, "/etc/mongrel_cluster/#{application}.yml"

