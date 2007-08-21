# used by Kete for search
namespace :deploy do
  namespace :zebra do
    desc "Start Zebra processes on the app server."
    task :start , :roles => :app do
      rake = fetch(:rake, 'rake')
      run "cd #{current_path}; #{rake} zebra:start"
    end

    desc "Stop Zebra processes on the app server."
    task :stop , :roles => :app do
      rake = fetch(:rake, 'rake')
      run "cd #{current_path}; #{rake} zebra:stop"
    end

    desc "Restart the Zebra processes on the app server."
    task :restart , :roles => :app do
      zebra.stop
      zebra.start
    end
  end
end
