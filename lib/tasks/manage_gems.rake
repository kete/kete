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
    # All this replaced by Bundler
    p "This rake task has been replaced by Bundler, please use 'bundle install' or 'bundle update' instead."
  end

  namespace :required do
    desc "Install required gems"
    task :install do
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end

    desc "Update required gems"
    task :update do
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end

    desc "Check that you have required gems"
    task :check => :environment do
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end
  end

  namespace :management do
    desc "Install management gems"
    task :install do
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end

    desc "Update management gems"
    task :update do
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end
  end

  namespace :testing do
    desc "Install testing gems"
    task :install do
     Rake::Task['manage_gems:exec_action'].execute(ENV)
    end

    desc "Update testing gems"
    task :update do
      Rake::Task['manage_gems:exec_action'].execute(ENV)
    end
  end

end
