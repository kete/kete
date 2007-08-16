namespace :deploy do

  namespace :configs do
    desc "Sets up config directory in shared_path to store remote config files."
    task :setup do
      sudo "mkdir #{shared_path}/config"
      sudo "chown -R #{user}:#{group} #{shared_path}/config"
      sudo "chmod -R 775 #{shared_path}/config"
      deploy.mongrel.configure
    end

    after "deploy:setup", "deploy:configs:setup"
    desc "Puts config files on remote server."
    task :put_files do
      config_files.each do |file|
        put file, "#{file}"
        sudo "mv #{file} #{shared_path}/config/#{file}"
      end
      sudo "chown -R #{user} #{shared_path}/config"
      sudo "chmod -R 775 #{shared_path}/config"
    end

    after "deploy:update_code", "deploy:configs:copy"
    desc "Copy config files to live app"
    task :copy do
      config_files.each do |file|
        run "cp #{shared_path}/config/#{file} #{release_path}/config/"
      end
    end
  end

  task :restart do
    sudo "mongrel_rails cluster::restart -C #{mongrel_conf}"
  end

  task :start do
    sudo "mongrel_rails cluster::start -C #{mongrel_conf}"
  end

  task :stop do
    sudo "mongrel_rails cluster::stop -C #{mongrel_conf}"
  end

  desc "Shows tail of production log"
  task :tail do
    sudo "tail -f #{current_path}/log/production.log"
  end

  after "deploy:update_code", "deploy:copy_config_files"
  desc "Copy config files to live app"
  task :copy_config_files do
    config_files.each do |file|
      run "cp #{shared_path}/config/#{file} #{release_path}/config/"
    end
  end

end
