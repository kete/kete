# capistrano recipes specific to backgroundrb server

namespace :deploy do

  namespace :backgroundrb do

    desc "Start backgroundrb server"
    task :start, :roles => :app do
      run "cd #{current_path} && script/backgroundrb start"
    end

    desc "Stop backgroundrb server"
    task :stop, :roles => :app do
      begin
        run "if [ -f #{current_path}/config/backgroundrb.yml ]; then cd #{current_path} && script/backgroundrb stop; fi"
      rescue
        puts "WARNING: Failed to stop Backgroundrb, but not fatal. Continuing with deployment."
      end
    end

    desc "Restart backgroundrb server"
    task :restart, :roles => :app do
      deploy.backgroundrb.stop
      deploy.backgroundrb.start
    end

  end

end
