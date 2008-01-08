# lib/tasks/manage_gems.rake
#
# tasks related to required gems and software, some may need to be run with sudo
#
# Walter McGinnis, 2007-08-13
#
# $ID: $

# TODO: confirm proper way to call either invoke or execute for Rake > 1.8
# in this context
# if using invoke @already_run is set to true for rake prep_app, too early
# I'm not super happy about calling .execute with ENV as argument... but maybe that is correct
require 'yaml'
require 'required_software'
include RequiredSoftware

desc "Tasks related to gems for Kete. Requires sudo privilege. See config/required_software.yml for list. Expect numerous warnings that can ignore."
namespace :manage_gems do
  task :exec_action do
    p "Requires sudo or root privileges.  You will be prompted for password if necessary."
    # default
    ENV['GEMS_ACTION'] ||= 'update'

    required = load_required_software
    required[ENV['GEMS_TO_GRAB']].keys.each do |gem_name|
      p gem_name
      `sudo gem #{ENV['GEMS_ACTION']} #{gem_name}`
    end
  end

  namespace :required do
    desc "Install required gems"
    task :install do
      ENV['GEMS_TO_GRAB'] = 'gems'
      ENV['GEMS_ACTION'] = 'install'
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end

    desc "Update required gems"
    task :update do
      ENV['GEMS_TO_GRAB'] = 'gems'
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end

    desc "Check that you have required gems"
    task :check do
      required_software = load_required_software

      missing_lib_count = 0
      p "Missing Gems or Libs:"
      missing_libs(required_software).each do |lib|
        p lib
        missing_lib_count += 0
      end
      if missing_lib_count > 0
        p "You have to install the above for Kete to work.\nUsually \"sudo gem install gem_name\", but double check documentation.  For example Rmagick is usually best installed via a port or package."
      else
        p "None.  Feel free to proceed."
      end
    end
  end

  namespace :management do
    desc "Install management gems"
    task :install do
      ENV['GEMS_TO_GRAB'] = 'management_gems'
      ENV['GEMS_ACTION'] = 'install -y'
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end

    desc "Update management gems"
    task :update do
      ENV['GEMS_TO_GRAB'] = 'management_gems'
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end
  end
end
