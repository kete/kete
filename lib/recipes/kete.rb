# kete specific capistrano recipes

namespace :deploy do

  desc "Run the steps necessary to get Kete going for the first time.  May take awhile."
  task :first_time do
    deploy.setup
    deploy.update_code
    deploy.kete.prepare.setup_zebra
    deploy.kete.prepare.setup_imports
    deploy.kete.prepare.setup_private
    deploy.kete.prepare.setup_themes
    deploy.symlink
    deploy.symlink.all
    deploy.gems.install
    deploy.db.bootstrap
    deploy.restart
  end

  desc "Run the steps necessary to update Kete. Overrides the default Capistrano task."
  task :update do
    deploy.backgroundrb.stop
    run "cd #{current_path} && rake tmp:cache:clear"
    deploy.update_code
    deploy.symlink
    deploy.kete.symlink.all
    deploy.gems.update
    deploy.migrate
    deploy.kete.upgrade
    deploy.backgroundrb.start
    deploy.restart
  end

  namespace :kete do

    desc 'Upgrade Kete Installation'
    task :upgrade, :role => :app do
      run "cd #{current_path} && RAILS_ENV=#{app_environment} rake kete:upgrade"
    end

    desc "What to we need to happen after code checkout, but before the app is ready to be started."
    namespace :prepare do

      desc "The directory that holds everything related to zebra needs to live under share/system/zebradb"
      task :setup_zebra, :roles => :app do
        run "cp -r #{latest_release}/zebradb #{shared_path}/system/"
      end

      desc "The directory that holds everything related to imports needs to live under share/system/imports"
      task :setup_imports, :roles => :app do
        run "cp -r #{latest_release}/imports #{shared_path}/system/"
      end

      desc "The directory that holds everything related to private items needs to live under share/system/private"
      task :setup_private, :roles => :app do
        run "cp -r #{latest_release}/private #{shared_path}/system/"
      end

      desc "The directory that holds everything related to themes needs to live under share/system/themes"
      task :setup_themes, :roles => :app do
        run "cp -r #{latest_release}/public/themes #{shared_path}/system/"
      end

    end

    desc "Symlink folders for existing Kete installations"
    namespace :symlink do

      public_dirs = %w{ audio documents image_files video themes }
      non_public_dirs = %w{ zebradb imports private }
      all_dirs = public_dirs + non_public_dirs

      desc "Symlink all files"
      task :all do
        all_dirs.each do |dir|
          eval("deploy.kete.symlink.#{dir}")
        end
      end

      public_dirs.each do |dir|
        desc "Symlink the /public/#{dir} directory"
        task dir.to_sym, :role => :app do
          symlink_system_directory(dir)
        end
      end

      non_public_dirs.each do |dir|
        desc "Symlink the /#{dir} directory"
        task dir.to_sym, :role => :app do
          symlink_system_directory(dir, false)
        end
      end

      def symlink_system_directory(dir, is_public=true)
        public_dir = is_public ? 'public/' : ''
        run "mkdir -p #{shared_path}/system/#{dir}"
        run "rm -rf #{current_path}/#{public_dir}#{dir}"
        run "ln -nfs #{shared_path}/system/#{dir} #{current_path}/#{public_dir}#{dir}"
      end

    end

    def set_app_environment
      set :app_environment, 'production' unless defined?(app_environment)
    end

  end

end
