require 'capistrano/recipes/deploy/strategy'
# Allows you to deploy Mint from the comfort of your own app. Gobs of
# code borrowed from Geoff Rosenbach's original Mint deployment recipe.
# 
# Usage: Set the appropriate variables. Make sure to include this file in your
# Capfile by inserting the following line (or something to that effect):
#   
#     load 'path/to/this'
# 
# If you're confused, see your Capfile for examples on how it's done.
#
# Now all you have to do is run "cap deploy:mint" and Mint will be deployed. 
#
# Check for new updates of this script frequently. Hopefully I'll be able to 
# extend the functionality of it, as well as clean up some of the spots that
# I know are probably not "the Ruby way."

namespace :deploy do
  namespace :mint do
    
    desc "Configure Mint virtual server on remote app."
    task :setup do
      logger.info "generating .conf file"
      conf = Net::HTTP.get URI.parse('http://svn.nakadev.com/templates/basicvirtualhost.conf')
      require 'erb'
      result = ERB.new(conf).result(binding)
      put result, "#{application}.conf"
      logger.info "placing #{application}.conf on remote server"
      sudo "mv #{application}.conf #{apache_conf}"
      sudo "chown #{user}:users #{apache_conf}"
      sudo "chmod 775 #{apache_conf}"
    end
  
    before "deploy:mint:update_code", "deploy:mint:set_vars"
    # Sets variables to traditional names
    task :set_vars do
      set :repository, mint_repository
      set :deploy_to, mint_deploy_to
      set :deploy_via, mint_deploy_via
    end
  
    # TODO Refactor to not rewrite default deployment task
    desc "Deploy Mint stats tracking."
    task :default do
      update_code
      symlink
    end
    
    task :update_code, :except => { :no_release => true } do
      on_rollback { run "rm -rf #{release_path}; true" }
      strategy.deploy!
      finalize_update
    end
  
    # Overridden since PHP doesn't have some of the Rails directories
    task :finalize_update, :except => { :no_release => true } do
      # Make directories writeable by the deployment user's group
      run "chmod -R g+w #{release_path}" if fetch(:group_writable, true)
    end

    # Symlinks 
    task :symlink, :except => { :no_release => true } do
      on_rollback { run "rm -f #{current_path}; ln -s #{previous_release} #{current_path}; true" }
      run "rm -f #{current_path} && ln -s #{release_path} #{current_path}"
    end

    task :restart, :roles => :app do
      # Do nothing
    end

    # Copy db files
    after "deploy:mint:update_code", "deploy:mint:copy_db_config"
    desc "Copy Mint DB config"
    task :copy_db_config, :roles => :app do
      run "cp #{app_shared}/config/db.php #{release_path}/config/db.php"
      run "chmod -R 775 #{release_path}/config/db.php"
    end

    # Post-deploy cleanup
    task :after_default, :roles => :app do
      # Keep last 5 releases
      deploy.cleanup
    end
    
  end
end