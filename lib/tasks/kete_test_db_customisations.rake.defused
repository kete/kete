# lib/tasks/kete_testdb_customizations.rake
#
# overrides rake db:test:prepare to do kete specific set up
# add selenium test task
#
# This code lets us redefine existing Rake tasks, which is
# extremely handy for modifying existing Rails rake tasks.
#

# lib/tasks/kete_testdb_customizations.rake
#
# overrides rake db:test:prepare to do kete specific set up
#
# Walter McGinnis, 2007-10-25
#
# based on
# http://ajaxonrails.blogspot.com/2006/09/how-to-prepare-test-database.html work
# by Sur Max

# This code lets us redefine existing Rake tasks, which is extremely
# handy for modifying existing Rails rake tasks.
# Credit for this snippet of code goes to Jeremy Kemper
# http://pastie.caboo.se/9620
unless Rake::TaskManager.methods.include?(:redefine_task)
  module Rake
    module TaskManager
      def redefine_task(task_class, args, &block)
        task_name, deps = resolve_args([args])
        task_name = task_class.scope_name(@scope, task_name)
        deps = [deps] unless deps.respond_to?(:to_ary)
        deps = deps.collect {|d| d.to_s }
        task = @tasks[task_name.to_s] = task_class.new(task_name, self)
        task.application = self
        task.add_description(@last_description)
        @last_description = nil
        task.enhance(deps, &block)
        task
      end
    end
    class Task
      class << self
        def redefine_task(args, &block)
          Rake.application.redefine_task(self, args, &block)
        end
      end
    end
  end
end

namespace :test do
  Rake::TestTask.new(:selenium => "db:test:prepare") do |t|
    t.libs << "test"
    t.pattern = 'test/selenium/**/*_test.rb'
    t.verbose = true
  end
  Rake::Task['test:selenium'].comment = "Run the selenium tests in test/selenium"
end

namespace :db do
  namespace :test do
    desc 'Prepare the test database with the bootstrapped data necessary for Kete'
    Rake::Task.redefine_task(:prepare => :environment) do
      # this is a hack to make sure that RAILS_ENV is set to 'test'
      # when we redefine this task
      RAILS_ENV = 'test'
      ENV['RAILS_ENV'] = 'test'

      require File.expand_path(File.dirname(__FILE__) + "/../required_software")
      require File.expand_path(File.dirname(__FILE__) + "/../../test/common_test_methods")
      #load_testing_libs
      verify_zebra_changes_allowed
      Rake::Task['db:bootstrap'].invoke
    end
  end
end
