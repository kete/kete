# capistrano recipes to manage gems

namespace :deploy do

  namespace :gems do

    desc 'Install Required Gems'
    task :install, :role => :app do
      run "cd #{current_path} && sudo rake manage_gems:required:install"
    end

    desc 'Update Required Gems'
    task :update, :role => :app do
      run "cd #{current_path} && sudo rake manage_gems:required:update"
    end

  end

end