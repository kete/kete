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

desc "Tasks related to gems for Kete. See config/required_software.yml for list."
namespace :manage_gems do
  task :exec_action do
    # default
    ENV['GEMS_ACTION'] ||= 'update'

    if `echo $USER`.strip.downcase != 'root'
      puts "\n/!\\ IMPORTANT /!\\\n\n"
      puts "This script has detected you are trying to run this as either a non root account or using sudo."
      puts "Please make sure you are installing these gems as a root user or as a user that will install gems in the system wide location."
      puts "Installing them as anyone without permission to the gem paths will install to your user account, not system wide."
      puts "This will cause issues later on with the web server being unable to locate gems."
      puts "Some operating systems, such as Debian Lenny, also have issues installing to the right place when using sudo."
      puts ""
      puts "If you are sure that you have permission to write to the correct location, please continue."
      puts "Otherwise press CTRL+C to abort, login as root, and run this task again. "
      STDIN.gets
    end

    no_rdoc_or_ri = '--no-rdoc --no-ri'

    required = load_required_software
    required[ENV['GEMS_TO_GRAB']].each do |key,value|
      if !value.blank? && value.kind_of?(Hash)

        # Pre install command (like clearing old gem versions)
        unless value['pre_command'].blank?
          p value['pre_command']
          `#{value['pre_command']}`
        end

        # If this gem relies on dependancies it doesn't properly take care of, manually install them
        unless value['gem_deps'].blank?
          value['gem_deps'].each do |dependancy_key,dependancy_value|
            p "gem #{ENV['GEMS_ACTION']} #{no_rdoc_or_ri} #{dependancy_key}"
            `gem #{ENV['GEMS_ACTION']} #{no_rdoc_or_ri} #{dependancy_key}`
          end
        end

        if !value['gem_repo'].blank?
          # we don't have a gem available for what we need, build it
          raise "rake_build_gem command not present" if value['rake_build_gem'].blank?
          raise "rake_install_gem command not present" if value['rake_install_gem'].blank?
          p "cd tmp && git clone #{value['gem_repo']} #{key} && cd #{key} && #{value['rake_build_gem']} && #{value['rake_install_gem']}"
          `cd tmp && git clone #{value['gem_repo']} #{key} && cd #{key} && #{value['rake_build_gem']} && #{value['rake_install_gem']}`
          p "Cleaning up #{key}"
          `cd tmp && rm -rf #{key}`
        else
          # we are installing a prebuilt gem
          gem_name = value['gem_name'] || key
          version = " --version='#{value['version']}'" unless value['version'].blank?
          source = " --source=#{value['source']}" unless value['source'].blank?
          p "gem #{ENV['GEMS_ACTION']} #{no_rdoc_or_ri} #{gem_name}#{version}#{source}"
          `gem #{ENV['GEMS_ACTION']} #{no_rdoc_or_ri} #{gem_name}#{version}#{source}`
        end

      else
        p "gem #{ENV['GEMS_ACTION']} #{no_rdoc_or_ri} #{key}"
        `gem #{ENV['GEMS_ACTION']} #{no_rdoc_or_ri} #{key}`
      end
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
    task :check => :environment do
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
      ENV['GEMS_ACTION'] = 'install'
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
      ENV['GEMS_ACTION'] = 'install'
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end

    desc "Update testing gems"
    task :update do
      ENV['GEMS_TO_GRAB'] = 'testing_gems'
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end
  end

end
