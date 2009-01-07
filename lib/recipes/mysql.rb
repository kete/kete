# This file is unused/unmaintained

# MySQL recipe (unfinished)
namespace :deploy do
  namespace :mysql do

    desc "Sets up mysql databse"
    task :setup do
      read_config
      sudo "mysqladmin create #{db_name}"
    end

    desc "Kills then starts mysqld process."
    task :kill do
      sudo "kill `cat /var/run/mysqld/mysqld.pid`"
    end

    desc "Starts mysqld process"
    task :start do
      sudo "mysqld --skip-grant-tables"
    end

    desc "Checks to make sure mysqld is active"
    task :ping do
      logger.info "pinging mysqld process"
      run "mysqladmin ping -u root"
    end

    desc "View the arguments passed to mysqld when it started."
    task :defaults do
      run "mysqladmin --print-defaults -u root"
    end

    namespace :status do
      desc "View mysql status information"
      task :default do
        run "mysqladmin status"
      end

      desc "View exensive mysql status information"
      task :more do
        run "mysqladmin extended-status"
      end
    end

    def read_config
      db_config = YAML.load_file('config/database.yml')
      set :db_user, db_config[rails_env]["username"]
      set :db_password, db_config[rails_env]["password"]
      set :db_name, db_config[rails_env]["database"]
    end

  end
end