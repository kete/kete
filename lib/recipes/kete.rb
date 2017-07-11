# kete specific capistrano recipes

namespace :deploy do
  task :default do
    puts "This task shouldn't be run. Use deploy:first_time or deploy:update"
  end

  desc 'Run the steps necessary to get Kete going for the first time.  May take awhile.'
  task :first_time do
    deploy.setup
    deploy.update_code
    deploy.kete.prepare.setup_zebra
    deploy.kete.prepare.setup_imports
    deploy.kete.prepare.setup_private
    deploy.kete.prepare.setup_themes
    deploy.kete.prepare.setup_locales
    deploy.symlink
    deploy.kete.symlink.all
    deploy.gems.install
    deploy.db.bootstrap
    deploy.restart
  end

  desc 'Run the steps necessary to update Kete. Overrides the default Capistrano task.'
  task :update do
    deploy.backgroundrb.stop
    run "cd #{current_path} && rake tmp:cache:clear"
    deploy.update_code
    deploy.symlink
    deploy.kete.symlink.all
    deploy.gems.update if (ENV['UPDATE_GEMS'] || false)
    deploy.migrate
    deploy.kete.upgrade
    deploy.kete.configure_imageselector
    deploy.backgroundrb.start
    deploy.restart
  end

  namespace :kete do
    desc 'Upgrade Kete Installation'
    task :upgrade, role: :app do
      set_app_environment
      run "cd #{current_path} && RAILS_ENV=#{app_environment} rake kete:upgrade"
    end

    desc 'What to we need to happen after code checkout, but before the app is ready to be started.'
    namespace :prepare do
      desc 'The directory that holds everything related to zebra needs to live under share/system/zebradb'
      task :setup_zebra, roles: :app do
        run "cp -r #{latest_release}/zebradb #{shared_path}/system/"
      end

      desc 'The directory that holds everything related to imports needs to live under share/system/imports'
      task :setup_imports, roles: :app do
        run "cp -r #{latest_release}/imports #{shared_path}/system/"
      end

      desc 'The directory that holds everything related to private items needs to live under share/system/private'
      task :setup_private, roles: :app do
        run "cp -r #{latest_release}/private #{shared_path}/system/"
      end

      desc 'The directory that holds everything related to themes needs to live under share/system/themes'
      task :setup_themes, roles: :app do
        run "cp -r #{latest_release}/public/themes #{shared_path}/system/"
      end

      desc 'The directory that holds locales (translations) needs to live under share/system/locales'
      task :setup_locales, roles: :app do
        run "cp -r #{latest_release}/config/locales #{shared_path}/system/"
      end
    end

    desc 'Symlink folders for existing Kete installations'
    namespace :symlink do
      public_dirs = %w{audio documents image_files video themes}
      root_dirs = %w{zebradb imports private}
      config_dirs = %w{locales}
      all_dirs = public_dirs + root_dirs + config_dirs

      desc 'Symlink all files'
      task :all do
        all_dirs.each do |dir|
          eval("deploy.kete.symlink.#{dir}")
        end
      end

      root_dirs.each do |dir|
        desc "Symlink the /#{dir} directory"
        task dir.to_sym, role: :app do
          symlink_system_directory(dir)
        end
      end

      config_dirs.each do |dir|
        desc "Symlink the /config/#{dir} directory"
        task dir.to_sym, role: :app do
          symlink_system_directory(dir, 'config/')
        end
      end

      public_dirs.each do |dir|
        desc "Symlink the /public/#{dir} directory"
        task dir.to_sym, role: :app do
          symlink_system_directory(dir, 'public/')
        end
      end

      # For each directory, setup a system folder, copy the repository files to it,
      # remove the folder from the current directory and in it's place, put a symlink
      def symlink_system_directory(dir, prefix = '')
        run "mkdir -p #{shared_path}/system/#{dir}"
        # The keteaccess password file is rewritten later.
        # Let's just move it to make sure we can fall back to something if it goes wrong
        run "if [ -f #{shared_path}/system/zebradb/keteaccess ]; then mv #{shared_path}/system/zebradb/keteaccess #{shared_path}/system/zebradb/keteaccess.old; fi" if dir == 'zebradb'
        run "if [ -d #{current_path}/#{prefix}#{dir} ]; then cp -rf #{current_path}/#{prefix}#{dir} #{shared_path}/system/; fi"
        run "rm -rf #{current_path}/#{prefix}#{dir}"
        run "ln -nfs #{shared_path}/system/#{dir} #{current_path}/#{prefix}#{dir}"
      end
    end

    def set_app_environment
      begin; app_environment; rescue; set(:app_environment, 'production'); end
    end

    desc 'Update Kete TinyMCE imageselector plugin configuration to reflect Kete system settings'
    task :configure_imageselector, role: :app do
      set_app_environment
      run "cd #{current_path} && RAILS_ENV=#{app_environment} rake kete:tools:tiny_mce:configure_imageselector"
    end
  end
end
