# capistrano recipes specific to zebra server

# used by Kete for search
namespace :deploy do
  namespace :zebra do
    desc 'Start Zebra processes'
    task :start, roles: :app do
      run "cd #{current_path} && rake zebra:start"
    end

    desc 'Stop Zebra processes'
    task :stop, roles: :app do
      run "cd #{current_path} && rake zebra:stop"
    end

    desc 'Restart Zebra processes'
    task :restart, roles: :app do
      zebra.stop
      zebra.start
    end
  end
end
