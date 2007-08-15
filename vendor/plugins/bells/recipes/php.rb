# Capistrano PHP Deployment Recipe
# Created by Pat Nakajima
#
#   To use this recipe successfully, you need to do a few things:
# * Create the folder in which you'd like to deploy the project
#   on the remote server

namespace :deploy do
    
  desc "Configure virtual server on remote app."
  task :setup do
    logger.info "generating .conf file"
    conf = Net::HTTP.get URI.parse('http://svn.nakadev.com/templates/basicvirtualhost.conf')
    require 'erb'
    result = ERB.new(conf).result(binding)
    put result, "#{application}.conf"
    logger.info "putting #{application}.conf on #{domain}"
    put result, "#{application}.conf"
    sudo "mv #{application}.conf #{apache_conf}"
    sudo "chown #{user}:#{group} #{apache_conf}"
    sudo "chmod 775 #{apache_conf}"
  end

  # This part is borrowed from Geoffrey Grosenbach.
  # Overridden since PHP doesn't have some of the Rails directories
  task :finalize_update, :except => { :no_release => true } do
    # Make directories writeable by the deployment user's group
    run "chmod -R g+w #{release_path}" if fetch(:group_writable, true)
  end

  task :restart, :roles => :app do
    # Do nothing (I have a different recipe to restart Apache.)
  end
  
end