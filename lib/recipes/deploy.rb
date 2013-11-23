# general capistrano recipes to restart application server
namespace :deploy do
  desc "Start Application Server"
  task :start do
    deploy.apache.start
  end

  desc "Stop Application Server"
  task :stop do
    deploy.apache.stop
  end

  desc "Restart Application Server"
  task :restart do
    deploy.apache.restart_app
  end
end
