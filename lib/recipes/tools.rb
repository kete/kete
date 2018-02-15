# This file is unused/unmaintained

namespace :tools do
  rake_whitelist = [
    'acts_as_licensed:import_au_cc_licenses', 'acts_as_licensed:import_nz_cc_licenses',
    'kete:export:users', 'kete:import:users',
    'kete:repair:check_uploaded_files', 'kete:repair:correct_upload_locations', 'kete:repair:fix_topic_versions', 'kete:repair:set_missing_contributors',
    'kete:tools:remove_robots_txt',
    'log:clear',
    'time:zones:all', 'time:zones:local', 'time:zones:us',
    'tmp:cache:clear', 'tmp:clear', 'tmp:create', 'tmp:pids:clear', 'tmp:sessions:clear', 'tmp:sockets:clear'
  ]

  desc 'Run a rake command on the deploy server (some are disabled). Set RAKE_CMD to the task name, and RAKE_ENV (if needed) to the environment you want to run the task in.'
  task :rake_run do
    abort 'ERROR: Use RAKE_CMD to set the rake task you want to run (without the rake command itself).' unless ENV['RAKE_CMD']
    abort 'ERROR: Cannot run a rake task that could lead to corrupt data. Run it on the actual server.' unless rake_whitelist.include?(ENV['RAKE_CMD'])
    environment = ENV['RAKE_ENV'] ? "RAILS_ENV=#{ENV['RAKE_ENV']}" : ''
    run "cd #{current_path} && #{environment} rake #{ENV['RAKE_CMD']}"
  end

  desc 'Shows tail of production log'
  task :tail do
    environment = ENV['RAILS_ENV'] || 'production'
    run "tail -f #{current_path}/log/#{environment}.log"
  end

  task :default do
    desc = <<-DESC

      Capistrano Bells
      Tools Recipe
      Tasks for the general maintenance and development of web applications.

    DESC
    puts desc
  end

  namespace :ssh do
    # TODO Create SSH key generation task

    desc 'Copies contents of ssh public keys into authorized_keys file'
    task :setup do
      sudo 'test -d ~/.ssh || mkdir ~/.ssh'
      sudo 'chmod 0700 ~/.ssh'
      put(
        ssh_options[:keys].collect { |key| File.read(key + '.pub') }.join("\n"),
        File.join('/home', user, '.ssh/authorized_keys'),
        mode: 0600
      )
    end
  end

  desc 'Displays server uptime'
  task :uptime do
    run 'uptime'
  end

  desc 'Look for necessary commands for Rails deployment on remote server.'
  task :look_for_commands do
    %w[ruby rake svn].each do |command|
      run "which #{command}"
    end
  end

  namespace :aptitude do
    desc 'Runs aptitude update on remote server'
    task :update do
      logger.info 'Running aptitude update'
      sudo 'aptitude update'
    end

    desc 'Runs aptitude upgrade on remote server'
    task :upgrade do
      sudo_with_input 'aptitude upgrade', /^Do you want to continue\?/
    end

    desc 'Search for aptitude packages on remote server'
    task :search do
      puts 'Enter your search term:'
      deb_pkg_term = $stdin.gets.chomp
      logger.info 'Running aptitude update'
      sudo 'aptitude update'
      stream "aptitude search #{deb_pkg_term}"
    end

    desc 'Installs a package using the aptitude command on the remote server.'
    task :install do
      puts 'What is the name of the package(s) you wish to install?'
      deb_pkg_name = $stdin.gets.chomp
      raise 'Please specify deb_pkg_name' if deb_pkg_name == ''
      logger.info 'Updating packages...'
      sudo 'aptitude update'
      logger.info "Installing #{deb_pkg_name}..."
      sudo_with_input "aptitude install #{deb_pkg_name}", /^Do you want to continue\?/
    end
  end

  namespace :svn do
    desc 'remove and ignore log files and tmp from subversion'
    task :clean do
      logger.info 'removing log directory contents from svn'
      system 'svn remove log/*'
      logger.info 'ignoring log directory'
      system "svn propset svn:ignore '*.log' log/"
      system 'svn update log/'
      logger.info 'ignoring tmp directory'
      system "svn propset svn:ignore '*' tmp/"
      system 'svn update tmp/'
      logger.info 'committing changes'
      system "svn commit -m 'Removed and ignored log files and tmp'"
    end

    desc 'Add new files to subversion'
    task :add do
      logger.info 'Adding unknown files to svn'
      system "svn status | grep '^\?' | sed -e 's/? *//' | sed -e 's/ /\ /g' | xargs svn add"
    end

    desc 'Commits changes to subversion repository'
    task :commit do
      puts 'Enter log message:'
      m = $stdin.gets.chomp
      logger.info 'Committing changes...'
      system "svn commit -m #{m}"
    end

    task :install do
      sudo "chown -R #{user}:#{group} /usr/local/src"
      run 'cd /usr/local/src && wget http://subversion.tigris.org/downloads/subversion-1.4.4.tar.gz'
      stream 'tar -zxvf /usr/local/src/subversion-1.4.4.tar.gz'
      run '/usr/local/src/subversion-1.4.4/configure && make && sudo make install'
    end
  end

  namespace :gems do
    task :default do
      desc <<-DESC

        Tasks to adminster Ruby Gems on a remote server: \
         \
        cap tools:gems:list \
        cap tools:gems:update \
        cap tools:gems:install \
        cap tools:gems:remove \

      DESC
      puts desc
    end

    desc 'List gems on remote server'
    task :list do
      stream 'gem list'
    end

    desc 'Update gems on remote server'
    task :update do
      sudo 'gem update'
    end

    desc 'Install a gem on the remote server'
    task :install do
      # TODO Figure out how to use Highline with this
      puts "Enter the name of the gem you'd like to install:"
      gem_name = $stdin.gets.chomp
      logger.info "trying to install #{gem_name}"
      sudo "gem install #{gem_name}"
    end

    desc 'Uninstall a gem from the remote server'
    task :remove do
      puts "Enter the name of the gem you'd like to remove:"
      gem_name = $stdin.gets.chomp
      logger.info "trying to remove #{gem_name}"
      sudo "gem install #{gem_name}"
    end
  end

  #  Tab completion task (unfinished)
  #  namespace :tabs do
  #
  #    desc "Install tab completion enabler script"
  #    task :setup do
  #      system "sudo cp vendor/plugins/bells/recipes/templates/complete /usr/local/bin/"
  #      system "sudo chmod 755 /usr/local/bin/complete"
  #      File.open("~/.bashrc", File::WRONLY|File::APPEND|File::CREAT) { |f| f.puts 'complete -C /usr/local/bin/complete -o default cap' }
  #    end
  #
  #    desc "Update capistrano tab completion."
  #    task :update do
  #      system "rm ~/.captabs"
  #    end
  #
  #  end
end
