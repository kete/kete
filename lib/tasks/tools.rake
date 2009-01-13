# lib/tasks/tools.rake
#
# miscellaneous tools for kete (clearing robots.txt file)
#
# Kieran Pilkington, 2008-10-01
#
namespace :kete do
  namespace :tools do
    desc 'Remove /robots.txt (will rebuild next time a bot visits the page)'
    task :remove_robots_txt => :environment do
      path = "#{RAILS_ROOT}/public/robots.txt"
      File.delete(path) if File.exist?(path)
    end

    desc 'Resets the database and zebra to their preconfigured state.'
    task :reset => ['kete:tools:reset:zebra', 'db:bootstrap']
    namespace :reset do

      desc 'Stops and clears zebra'
      task :zebra => :environment do
        Rake::Task["zebra:stop"].invoke
        Rake::Task["zebra:init"].invoke
        ENV['ZEBRA_DB'] = 'private'
        Rake::Task["zebra:init"].invoke
      end
    end
  end
end
