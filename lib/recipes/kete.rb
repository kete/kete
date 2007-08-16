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
      deploy.update
      deploy.prepare
      deploy.start
    end
  end

  desc "What to we need to happen after code checkout, but before the app is ready to be started."
  namespace :prepare do
    desc "Prepare required software, initialize database, etc."
    task :default do
      install_gems
      setup_zebra
      db_bootstrap
    end

    desc "Installs required gems for Kete"
    task :install_gems, :roles => :app do
      sudo 'rake manage_gems:required:install'
      # TODO: take this out after 0.4.0 of zoom is released
      sudo "wget http://waltermcginnis.com/zoom-0.4.0.gem && gem uninstall zoom && gem install -y zoom-0.4.0.gem"
    end

    desc "The directory that holds everything related to zebra needs to live under share/system/zebradb"
    task :setup_zebra, :roles => :app do
      run "cp -r #{release_path}/zebradb #{shared_path}/system/"
    end

    desc "Set up the database with migrations and default data."
    task :db_bootstrap , :roles => :db do
      run 'rake db:bootstrap'
    end
  end

  after "deploy:symlink", :add_kete_symlinks
  desc "Put in Kete's specific symlinks, not worrying about page caches (not using memcache for them yet) that get orphaned in the last release's public directory.  Just letting them expire."
  task :add_kete_symlinks do
    # handle file upload directories
    %{audio documents image_files video}.each do |share|
      # this WON'T overwrite an existing directory, just create it if it's not there
      run "mkdir -p #{shared_path}/system/#{share}"
      run "ln -nfs #{shared_path}/system/#{share} #{release_path}/public/#{share}"
    end

    # handle our zebra databases
    # assumes that the shared/system/zebradb exists, should be handled by deploy:first_time
    run "ln -nfs #{shared_path}/system/#{share} #{release_path}/public/#{share}"
  end
end
