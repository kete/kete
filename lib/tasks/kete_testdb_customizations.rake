# lib/tasks/kete_testdb_customizations.rake
#
# overrides rake db:test:prepare to do kete specific set up
#
# Walter McGinnis, 2007-10-25
#
# based on
# http://ajaxonrails.blogspot.com/2006/09/how-to-prepare-test-database.html work
# by Sur Max

module Rake
  module TaskManager
    def redefine_task(task_class, args, &block)
      task_name, deps = resolve_args(args)
      task_name = task_class.scope_name(@scope, task_name)
      deps = [deps] unless deps.respond_to?(:to_ary)
      deps = deps.collect {|d| d.to_s }
      task = @tasks[task_name.to_s] = task_class.new(task_name, self)
      task.application = self
      task.add_comment(@last_comment)
      @last_comment = nil
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

def redefine_task(args, &block)
  Rake::Task.redefine_task(args, &block)
end

namespace :db do
  namespace :test do
    desc 'Prepare the test database with the bootstrapped data necessary for Kete'
    redefine_task :prepare => :environment do
      RAILS_ENV = 'test'
      Rake::Task['db:bootstrap'].invoke
    end
  end
end
