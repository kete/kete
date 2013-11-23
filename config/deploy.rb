require "bundler/capistrano"

# support multi-stage deployment
# (requires capistrano-ext gem)
# require "capistrano/ext/multistage"

# support for ruby defined application configurations
# (requires capistrano-configuration)
# require "capistrano-configuration"

# What is your application called and where are you getting it from?
set :application, "set your application name here"
set :repository,  "set your repository location here"

# Where are your deployed applications?
# change this if you deploy to a different directory
# than what we outline in Kete installation guide
set :path_to_apps, "/home/kete/apps"

# Where on the server should this application reside?
set :deploy_to, "#{path_to_apps}/#{application}"

# version control settings
set :scm, :git
set :branch, "master"

# Which user/group on the server will be running the application?
set :user, "kete"
set :group, "kete"
# use ssh agent and forwarding rather than password
# see https://help.github.com/articles/using-ssh-agent-forwarding
set :ssh_options, { :forward_agent => true }

# Which server should we deploy to?
role :app, "your app-server here"
role :web, "your web-server here"
role :db,  "your db-server here", :primary => true

set :config_files, []

# keeps a checked out/cloned copy of the site on the deployed server so next time
# it updates the codebase, instead of redownloading the whole app (faster this way)
set :deploy_via, :remote_cache
