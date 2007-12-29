# config/recipes/backgroundrb.rb
#
# capistrano recipes specific to backgroundrb server
#
# Walter McGinnis, 2007-12-30
namespace :deploy do
  after "deploy:restart", "deploy:backgroundrb:restart"

  desc "Manage Backgroundrb server, expects config/backgroundrb.yml to exist and that we are in current release directory"
  namespace :backgroundrb do
    desc "Start backgroundrb server on the app server."
    task :start , :roles => :app do
      `script/backgroundrb start`
    end

    desc "Restart backgroundrb server on the app server."
    task :restart , :roles => :app do
      deploy.backgroundrb.stop
      deploy.backgroundrb.start
    end

    desc "Stop the backgroundrb server on the app server.  Handy if you have backgroundrb workers that have run amuck."
    task :stop , :roles => :app do
      `script/backgroundrb stop`
    end
  end
end
