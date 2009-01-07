# capistrano recipes specific to database server

namespace :deploy do

  namespace :db do

    desc 'Migrate the Database'
    task :migrate, :roles => :app do
      set_app_environment
      run "cd #{current_path} && RAILS_ENV=#{app_environment} rake db:migrate"
    end

    desc 'Bootstrap the Database'
    task :bootstrap, :roles => :app do
      set_app_environment
      run "cd #{current_path} && RAILS_ENV=#{app_environment} rake db:bootstrap"
    end

    def set_app_environment
      set :app_environment, 'production' unless defined?(app_environment)
    end

  end

end
