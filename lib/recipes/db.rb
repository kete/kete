# capistrano recipes specific to database server

namespace :deploy do

  namespace :db do

    desc 'Bootstrap the Database'
    task :bootstrap, :roles => :app do
      set_app_environment
      run "cd #{current_path} && RAILS_ENV=#{app_environment} rake db:bootstrap"
    end

    def set_app_environment
      begin; app_environment; rescue; set(:app_environment, 'production'); end
    end

  end

end
