# lib/tasks/tools.rake
#
# miscellaneous tools for kete (clearing robots.txt file)
#
# Kieran Pilkington, 2008-10-01
#
namespace :kete do
  namespace :tools do
    desc 'Restart application (Passenger specific)'
    task :restart do
      restart_result = system("touch #{RAILS_ROOT}/tmp/restart.txt")
      if restart_result
        puts "Restarted Application"
      else
        puts "Problem restarting Application."
      end
    end

    desc 'Remove /robots.txt (will rebuild next time a bot visits the page)'
    task :remove_robots_txt => :environment do
      path = "#{RAILS_ROOT}/public/robots.txt"
      File.delete(path) if File.exist?(path)
    end

    desc 'Copy config/locales.yml.example to config/locales.yml'
    task :set_locales do
      path = "#{RAILS_ROOT}/config/locales.yml"
      if File.exist?(path)
        puts "ERROR: Locales file already exists. Delete it first or run 'rake kete:tools:set_locales_to_default'"
        exit
      end
      require 'ftools'
      File.cp("#{RAILS_ROOT}/config/locales.yml.example", path)
      puts "config/locales.yml.example copied to config/locales.yml"
    end

    desc 'Overwrite existing locales by copying config/locales.yml.example to config/locales.yml'
    task :set_locales_to_default do
      puts "\n/!\\ WARNING /!\\\n\n"
      puts "This task will replace the existing config/locales.yml file with Kete's default\n"
      puts "Press any key to continue, or Ctrl+C to abort..\n"
      STDIN.gets
      path = "#{RAILS_ROOT}/config/locales.yml"
      File.delete(path) if File.exist?(path)
      Rake::Task["kete:tools:set_locales"].invoke
    end

    desc 'Resets the database and zebra to their preconfigured state.'
    task :reset => ['kete:tools:reset:zebra', 'db:bootstrap']
    namespace :reset do

      desc 'Stops and clears zebra'
      task :zebra => :environment do
        Rake::Task["zebra:stop"].invoke
        Rake::Task["zebra:init"].invoke
        ENV['ZEBRA_DB'] = 'private'
        Rake::Task["zebra:init"].execute(ENV)
      end
    end
  end
end
