include RequiredSoftware
def load_testing_libs(args = {})
  missing_gems = missing_libs(load_required_software, 'testing_gems', args)
  unless missing_gems.blank?
    puts "ERROR: Not all the nessesary gems are installed for these Tests to run."
    puts "Please run 'rake manage_gems:testing:install' to install them then try again."
    puts "Missing #{missing_gems.join(', ')}"
    exit
  end
end

def verify_zebra_changes_allowed
  return if ENV['ZEBRA_CHANGES_PERMITTED']
  puts "\n/!\\ IMPORTANT /!\\\n\n"
  puts "Testing currently uses the Zebra instance for this Kete codebase and will add, update and remove records from it.\n\n"
  puts "Do not run these tests unless you're sure that the Zebra search engine is not being used on a production host!\n\n"
  puts "Press any key to continue, or Ctrl+C to abort before any changes are made.."
  STDIN.gets
  ENV['ZEBRA_CHANGES_PERMITTED'] = 'true'
end

require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'tasks/rails'

# If Zebra is running, stop it, init it, start it, populate it
# If Zebra is running, same as the above but without a stop
def bootstrap_zebra_with_initial_records
  Rake::Task['zebra:stop'].execute(ENV) if zebra_running?('public') || zebra_running?('private')
  ENV['ZEBRA_DB'] = 'public'
  Rake::Task['zebra:init'].execute(ENV)
  ENV['ZEBRA_DB'] = 'private'
  Rake::Task['zebra:init'].execute(ENV)
  Rake::Task['zebra:start'].execute(ENV)
  Rake::Task['zebra:load_initial_records'].execute(ENV)
  unless zebra_running?('public') && zebra_running?('private')
    raise "ERROR: Zebra's public and private databases failed to start up properly. Double check configuration and try again."
  end
end

def zebra_running?(zebra_db)
  begin
    zoom_db = ZoomDb.find_by_database_name(zebra_db)
    Topic.process_query(:zoom_db => zoom_db, :query => "@attr 1=_ALLRECORDS @attr 2=103 ''")
    return true
  rescue
    return false
  end
end

def set_constant(constant, value)
  if respond_to?(:silence_warnings)
    silence_warnings do
      Object.send(:remove_const, constant) if Object.const_defined?(constant)
      Object.const_set(constant, value)
    end
  else
    Object.send(:remove_const, constant) if Object.const_defined?(constant)
    Object.const_set(constant, value)
  end
end

def configure_environment(&block)
  yield(block)
  # Reload the routes based on the current configuration
  ActionController::Routing::Routes.reload!
end
