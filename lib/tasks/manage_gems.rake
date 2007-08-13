# lib/tasks/manage_gems.rake
#
# tasks related to required gems, these need to be run with sudo
#
# Walter McGinnis, 2007-08-13
#
# $ID: $

require 'yaml'

desc "Tasks related to gems for Kete. Requires sudo privilege. See config/required_software.yml for list. Expect numerous warnings that can ignore."
namespace :manage_gems do
  # default
  ENV['GEMS_ACTION'] = 'update'

  task :exec_action => :environment do
    required = YAML.load_file("#{RAILS_ROOT}/config/required_software.yml")
    required[ENV['GEMS_TO_GRAB']].keys.each do |gem_name|
          `sudo gem #{ENV['GEMS_ACTION']} #{gem_name}`
    end
  end

  namespace :required do
    ENV['GEMS_TO_GRAB'] = 'gems'

    desc "Install required gems"
    task :install => :environment do
      ENV['GEMS_ACTION'] = 'install -y'
      Rake::Task['manage_gems:exec_action'].execute
    end

    desc "Update required gems"
    task :update => :environment do
      Rake::Task['manage_gems:exec_action'].execute
    end
  end

  namespace :management do
    ENV['GEMS_TO_GRAB'] = 'management_gems'

    desc "Install management gems"
    task :install => :environment do
      ENV['GEMS_ACTION'] = 'install -y'
      Rake::Task['manage_gems:exec_action'].execute
    end

    desc "Update management gems"
    task :update => :environment do
      Rake::Task['manage_gems:exec_action'].execute
    end
  end
end
