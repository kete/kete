# config/recipes/kete.rb
#
# capistrano recipes specific to our kete set up
# assumes debian etch target server
# so you mileage will vary
#
# a decent amount of these may be replaced by deprec 2
#
# Walter McGinnis, 2007-08-15
#
# $ID: $


namespace :deploy do
  desc "Wrapper for tasks to setup, update, prepare, then start our shiny new Kete"
  namespace :first_time do
    desc "Run the steps necessary to get Kete going for the first time.  May take awhile."
    task :default do
      deploy.setup
      deploy.update_code
      deploy.prepare.setup_zebra
      deploy.prepare.setup_imports
      deploy.symlink
      deploy.prepare.default
      deploy.start
    end
  end

  desc "What to we need to happen after code checkout, but before the app is ready to be started."
  namespace :prepare do
    desc "Prepare required software, initialize database, etc."
    task :default do
      install_gems
      db_bootstrap
    end

    desc "Installs required gems for Kete"
    task :install_gems, :roles => :app do
      rake = fetch(:rake, 'rake')
      rails_env = fetch(:rails_env, 'production')
      run "cd #{current_path}; #{rake} RAILS_ENV=production manage_gems:required:install"
    end

    desc "The directory that holds everything related to zebra needs to live under share/system/zebradb"
    task :setup_zebra, :roles => :app do
      run "cp -r #{latest_release}/zebradb #{shared_path}/system/"
    end

    desc "The directory that holds everything related to imports needs to live under share/system/imports"
    task :setup_imports, :roles => :app do
      run "cp -r #{latest_release}/imports #{shared_path}/system/"
    end

    desc "The directory that holds everything related to themes needs to live under share/system/themes"
    task :setup_themes, :roles => :app do
      run "cp -r #{latest_release}/public/themes #{shared_path}/system/"
    end

    desc "Set up the database with migrations and default data."
    task :db_bootstrap , :roles => :db do
      rake = fetch(:rake, 'rake')
      rails_env = fetch(:rails_env, 'production')
      run "cd #{current_path}; #{rake} RAILS_ENV=production db:bootstrap"
    end
  end

  desc "Any tasks that need to run to need to happen after we have updated our code, but before our site runs."
  namespace :upgrade do
    task :default do
      deploy.upgrade.run_upgrade
    end

    desc "Use upgrade rake task for Kete"
    task :run_upgrade, :roles => :app do
      rake = fetch(:rake, 'rake')
      rails_env = fetch(:rails_env, 'production')
      run "cd #{current_path}; #{rake} RAILS_ENV=production kete:upgrad"
    end
  end

  desc "Put in Kete's specific symlinks, not worrying about page caches (not using memcache for them yet) that get orphaned in the last release's public directory.  Just letting them expire."
  task :after_symlink do
    # handle file upload directories
    %w{audio documents image_files video}.each do |share|
      # this WON'T overwrite an existing directory, just create it if it's not there
      run "mkdir -p #{shared_path}/system/#{share}"
      run "ln -nfs #{shared_path}/system/#{share} #{current_path}/public/#{share}"
    end

    # handle our zebra databases
    # make system/zebradb if it doesn't exist already
    run "mkdir -p #{shared_path}/system/zebradb"
    run "rm -rf #{current_path}/zebradb"
    run "ln -nfs #{shared_path}/system/zebradb #{current_path}/"

    # handle our imports directory and all the stuff that lives in it
    # make system/imports if it doesn't exist already
    run "mkdir -p #{shared_path}/system/imports"
    run "rm -rf #{current_path}/imports"
    run "ln -nfs #{shared_path}/system/imports #{current_path}/"

    # handle our themes directory and all the stuff that lives in it
    # make system/themes if it doesn't exist already
    run "mkdir -p #{shared_path}/system/themes"
    run "rm -rf #{current_path}/public/themes"
    run "ln -nfs #{shared_path}/system/themes #{current_path}/public/themes"
  end
end
