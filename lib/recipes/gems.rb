# capistrano recipes to manage gems

namespace :deploy do

  namespace :gems do

    desc 'Install Required Gems'
    task :install, :role => :app do
      bundle install
    end

    desc 'Update Required Gems'
    task :update, :role => :app do
      bundle update
    end

  end

end