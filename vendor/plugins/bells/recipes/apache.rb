require 'net/http'
require 'uri'

# TODO Create installation tasks

namespace :deploy do
  namespace :apache do
  
    desc "Restarts Apache webserver"
    task :restart do
      sudo "#{apache_ctl} restart"
    end
  
    desc "Starts Apache webserver"
    task :start do
      sudo "#{apache_ctl} start"
    end
  
    desc "Stops Apache webserver"
    task :stop do
      sudo "#{apache_ctl} stop"
    end
    
    desc "Reload Apache webserver"
    task :reload_apache do
      sudo "#{apache_ctl} reload"
    end
    
    desc "Setup an apache virtual server on remote server. The directory that contains this file must be included in your httpd.conf file."
    task :setup do
      logger.info "generating .conf file"
      conf = Net::HTTP.get URI.parse('http://svn.nakadev.com/templates/virtualhost.conf')
      require 'erb'
      result = ERB.new(conf).result(binding)
      put result, "#{application}.conf"
      logger.info "placing #{application}.conf on remote server"
      sudo "mv #{application}.conf #{apache_conf}"
      sudo "chown #{user}:users #{apache_conf}"
      sudo "chmod 775 #{apache_conf}"
    end
  end
end

namespace :local do
  namespace :apache do
    desc "Start apache on local machine"
    task :start do
      puts "Starting Apache..."
      system "sudo #{local_apache_ctl_path} start"
    end
  
    desc "Stop apache on local machine"
    task :stop do
      puts "Stopping Apache..."
      system "sudo #{local_apache_ctl_path} stop"
    end
  
    desc "Restart apache on local machine"
    task :restart do
      puts "Restarting Apache..."
      system "sudo #{local_apache_ctl_path} restart"
    end
  end
end
