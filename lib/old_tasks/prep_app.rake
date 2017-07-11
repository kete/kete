# lib/tasks/prep_app.rake
#
# a wrapper task does most everything
# that we need done after initial checkout of the codebase
#
# Walter McGinnis, 2007-08-13
#
# $ID: $

desc 'A wrapper task that does most everything that we need done after initial checkout of the codebase.'
task :prep_app do
  p 'This may take awhile and have a lot of output.  You can ignore warnings.'

  # can't do tasks that need rails environment, apparently
  # , 'db:bootstrap'
  the_tasks = [ 'manage_gems:management:install', 'manage_gems:required:install']

  the_tasks.each do |t|
    Rake::Task[t].invoke
  end
end
