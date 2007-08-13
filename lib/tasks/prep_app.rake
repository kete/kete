# lib/tasks/prep_app.rake
#
# a wrapper task does most everything
# that we need done after initial checkout of the codebase
#
# Walter McGinnis, 2007-08-13
#
# $ID: $

desc "A wrapper task that does most everything that we need done after initial checkout of the codebase."
task :prep_app do
  p "Requires sudo or root privileges.  You will be prompted for password if necessary. This may take awhile and have a lot of output.  You can ignore warnings."

  the_tasks = [ 'manage_gems:management:install', 'manage_gems:required:install', 'db:bootstrap']

  the_tasks.each do |t|
    Rake::Task[t].invoke
  end
end
