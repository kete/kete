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
  task :exec_action do
    p "Requires sudo or root privileges.  You will be prompted for password if necessary."
    # default
    ENV['GEMS_ACTION'] ||= 'update'

    required = YAML.load_file("#{RAILS_ROOT}/config/required_software.yml")
    required[ENV['GEMS_TO_GRAB']].keys.each do |gem_name|
      p gem_name
      `sudo gem #{ENV['GEMS_ACTION']} #{gem_name}`
    end
  end

  namespace :required do
    desc "Install required gems"
    task :install do
      ENV['GEMS_TO_GRAB'] = 'gems'
      ENV['GEMS_ACTION'] = 'install -y'
      Rake::Task['manage_gems:exec_action'].execute
    end

    desc "Update required gems"
    task :update do
      ENV['GEMS_TO_GRAB'] = 'gems'
      Rake::Task['manage_gems:exec_action'].execute
    end
  end

  namespace :management do
    desc "Install management gems"
    task :install do
      ENV['GEMS_TO_GRAB'] = 'management_gems'
      ENV['GEMS_ACTION'] = 'install -y'
      Rake::Task['manage_gems:exec_action'].execute
    end

    desc "Update management gems"
    task :update do
      ENV['GEMS_TO_GRAB'] = 'management_gems'
      Rake::Task['manage_gems:exec_action'].execute
    end
  end
end
