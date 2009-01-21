# capistrano recipes specific to backgroundrb server
# Adapted from Capistrano Bells plugin (http://github.com/nakajima/capistrano-bells)

namespace :deploy do

  namespace :mongrel do

    desc "Configure Mongrel processes"
    task :configure, :roles => :app do
      set_mongrel_conf

      argv = []
      argv << "mongrel_rails cluster::configure"
      argv << "-N #{mongrel_servers.to_s}"
      argv << "-p #{mongrel_port.to_s}"
      argv << "-e #{mongrel_environment}"
      argv << "-a #{mongrel_address}"
      argv << "-c #{current_path}"
      argv << "-C #{mongrel_conf}"
      cmd = argv.join " "
      sudo cmd
    end

    desc "Start Mongrel processes"
    task :start, :roles => :app do
      set_mongrel_conf
      run "mongrel_rails cluster::start -C #{mongrel_conf}"
    end

    desc "Stop Mongrel processes"
    task :stop, :roles => :app do
      set_mongrel_conf
      run "mongrel_rails cluster::stop -C #{mongrel_conf}"
    end

    desc "Restart the Mongrel processes"
    task :restart, :roles => :app do
      set_mongrel_conf
      run "mongrel_rails cluster::restart -C #{mongrel_conf}"
    end

    desc "Deletes mongrel configuration file."
    task :delete, :roles => :app do
      set_mongrel_conf
      sudo "rm #{mongrel_conf}"
    end

    def set_mongrel_conf
      begin; mongrel_conf; rescue; set(:mongrel_conf, "/etc/mongrel_cluster/#{application}.yml"); end
    end

  end

end
