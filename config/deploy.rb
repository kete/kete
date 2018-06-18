# frozen_string_literal: true

# config valid only for Capistrano 3.1
lock '3.2.1'

set :application, 'kete'

set :repo_url, 'git@github.com:kete/kete.git'
set :branch, 'kete2'

# Can ask for the branch if you want to choose each time you deploy
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app
set :deploy_to, '/home/deploy/kete'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_files, %w{config/database.yml config/secrets.yml config/initializers/secret_token.rb config/application.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/audio public/documents public/image_files public/video public/system public/uploads}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
# set :keep_releases, 5

# Configure rbenv
# ###############

set :rbenv_type, :system
set :rbenv_custom_path, '/opt/rbenv'
set :rbenv_ruby, '2.1.2'
set :rbenv_prefix, "RAILS_ENV=#{fetch(:stage)} RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}
# set :rbenv_roles, :all # default value

# Configure Bundler
# #################
#
# https://github.com/capistrano/bundler
#
set :bundle_jobs, 4

# This task is a useful canary to figure out if you have configured capistrano
# correctly
desc 'Check that we can access everything'
task :check_write_perms do
  on roles(:all) do |host|
    if test("[ -w #{fetch(:deploy_to)} ]")
      info "#{fetch(:deploy_to)} is writable on #{host}"
    else
      error "#{fetch(:deploy_to)} is not writable on #{host}"
    end
  end
end

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sv 2 /home/deploy/service/kete'
    end
  end

  task :start do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sv start /home/deploy/service/kete'
    end
  end

  task :stop do
    on roles(:app), in: :sequence, wait: 5 do
      execute 'sv stop /home/deploy/service/kete'
    end
  end

  after :publishing, :restart

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end
end
