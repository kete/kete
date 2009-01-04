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
    required[ENV['GEMS_TO_GRAB']].each do |key,value|
      if !value.blank? && value.kind_of?(Hash)
        unless value['pre_command'].blank?
          p value['pre_command']
          `#{value['pre_command']}`
        end
        if !value['gem_repo'].blank?
          # we don't have a gem available for what we need, build it
          unless value['gem_deps'].blank?
            p "Install dependancies for building gem #{key} (#{value['gem_deps'].join(', ')})"
            value['gem_deps'].each do |dependancy_key,dependancy_value|
              `sudo gem install #{dependancy_key}`
            end
          end
          raise "rake_build_gem command not present" if value['rake_build_gem'].blank?
          raise "rake_install_gem command not present" if value['rake_install_gem'].blank?
          p "cd tmp && git clone #{value['gem_repo']} #{key} && cd #{key} && #{value['rake_build_gem']} && #{value['rake_install_gem']}"
          `cd tmp && git clone #{value['gem_repo']} #{key} && cd #{key} && #{value['rake_build_gem']} && #{value['rake_install_gem']}`
          p "Cleaning up #{key}"
          `cd tmp && sudo rm -rf #{key}`
        else
          # we are installing a prebuilt gem
          gem_name = value['gem_name']
          version = " --version=#{value['version']}" unless value['version'].blank?
          source = " --source=#{value['source']}" unless value['source'].blank?
          p "sudo gem #{ENV['GEMS_ACTION']} #{gem_name}#{version}#{source}"
          `sudo gem #{ENV['GEMS_ACTION']} #{gem_name}#{version}#{source}`
        end
      else
        p "sudo gem #{ENV['GEMS_ACTION']} #{key}"
        `sudo gem #{ENV['GEMS_ACTION']} #{key}`
      end
    end
  end

  namespace :required do
    desc "Install required gems"
    task :install do
      ENV['GEMS_TO_GRAB'] = 'gems'
      ENV['GEMS_ACTION'] = 'install -y'
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
      puts "Missing Gems or Libs:\n-----"
      missing_libs(required_software).each do |lib|
        puts lib
        missing_lib_count += 1
      end
      puts "-----"
      if missing_lib_count > 0
        puts "You have to install the above for Kete to work."
        puts "Usually \"sudo gem install gem_name\", but double check documentation.For example Rmagick is usually best installed via a port or package."
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

  namespace :testing do
    desc "Install testing gems"
    task :install do
      ENV['GEMS_TO_GRAB'] = 'testing_gems'
      ENV['GEMS_ACTION'] = 'install -y'
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end

    desc "Update testing gems"
    task :update do
      ENV['GEMS_TO_GRAB'] = 'testing_gems'
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end
  end

end
