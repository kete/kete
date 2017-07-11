# capistrano recipes specific to apache server
# Adapted from Capistrano Bells plugin (http://github.com/nakajima/capistrano-bells)

namespace :deploy do
  namespace :apache do
    desc 'Start Apache webserver'
    task :start, roles: :app do
      set_apache_clt
      sudo "#{apache_ctl} start"
    end

    desc 'Stop Apache webserver'
    task :stop, roles: :app do
      set_apache_clt
      sudo "#{apache_ctl} stop"
    end

    desc 'Restart Apache webserver'
    task :restart, roles: :app do
      set_apache_clt
      sudo "#{apache_ctl} restart"
    end

    desc 'Restart Rails Application'
    task :restart_app, roles: :app do
      run "cd #{current_path} && touch tmp/restart.txt"
    end

    def set_apache_clt
      begin; apache_ctl; rescue; set(:apache_ctl, '/etc/init.d/apache2'); end
    end
  end
end
