#
# A collection of methods shared between the unit/functional and integration test helpers
#

# The <tt>load_testing_libs</tt> method relies on methods in the RequiredSoftware module
include RequiredSoftware

# Load the gems needed, pass it to the <tt>missing_libs</tt> method which will return an array of missing gem dependancies
# Takes an optional args parameter which, at the moment, only allows you to exclude which gems get loaded through :exclude
# If there are gems missing (i.e. the missing_gems array is not blank) then output which are missing and exit the execution
def load_testing_libs(args = {})
  missing_gems = missing_libs(load_required_software, 'testing_gems', args)
  unless missing_gems.blank?
    puts "ERROR: Not all the nessesary gems are installed for these Tests to run."
    puts "Please run 'rake manage_gems:testing:install' to install them then try again."
    puts "Missing #{missing_gems.join(', ')}"
    exit
  end
end

# Currently the tests use the Zebra instance configured for the development/production mode, so when tests are run, the data
# in the database is overwritten, and this can be bad if you run it in a production host. So prevent accidental data manipulation
# we provide the person running the test a chance to back out, making it clear that Zebra will be affected if they continue.
# We use a ZEBRA_CHANGES_PERMITTED environment variable so that the prompt only occurs once per testing session, rather than 3
# times for each test type when 'rake test' is run
def verify_zebra_changes_allowed
  return if ENV['ZEBRA_CHANGES_PERMITTED']
  puts "\n/!\\ IMPORTANT /!\\\n\n"
  puts "Testing currently uses the Zebra instance for this Kete codebase and will add, update and remove records from it.\n\n"
  puts "Do not run these tests unless you're sure that the Zebra search engine is not being used on a production host!\n\n"
  puts "Press any key to continue, or Ctrl+C to abort before any changes are made.."
  STDIN.gets
  ENV['ZEBRA_CHANGES_PERMITTED'] = 'true'
end

# Include the necessary rake libraries for running Rake tasks within the tests. These are used for operations such as
# stopping/starting the Zebra database in <tt>bootstrap_zebra_with_initial_records</tt> and for clearing the tmp cache
require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'tasks/rails'

# Stop Zebra if it is running, initilize the databases (wiping them clean), start zebra, and load in some initial records ready
# for testing. If after that, Zebra has not loaded properly, raise an exception to inform the person running the tests
def bootstrap_zebra_with_initial_records
  # both of the silencers are need to supress the two types of messages Zebra outputs to the console
  silence_stream(STDERR) do
    silence_stream(STDOUT) do
      Rake::Task['zebra:stop'].execute(ENV) if zebra_running?('public') || zebra_running?('private')
      ENV['ZEBRA_DB'] = 'public'
      Rake::Task['zebra:init'].execute(ENV)
      ENV['ZEBRA_DB'] = 'private'
      Rake::Task['zebra:init'].execute(ENV)
      Rake::Task['zebra:start'].execute(ENV)
      Rake::Task['zebra:load_initial_records'].execute(ENV)
    end
  end
  unless zebra_running?('public') && zebra_running?('private')
    raise "ERROR: Zebra's public and private databases failed to start up properly. Double check configuration and try again."
  end
end

# Checks whether a Zebra database of a certain type (public or private) is currently running. If a query succeeds then its running
# and we return true, else we capture the exception when it fails, and return false
def zebra_running?(zebra_db)
  begin
    zoom_db = ZoomDb.find_by_database_name(zebra_db)
    Topic.process_query(:zoom_db => zoom_db, :query => "@attr 1=_ALLRECORDS @attr 2=103 ''")
    return true
  rescue
    return false
  end
end

# To change a constant, use this method. It removes any existing constant and sets the new one from the arguments passed in
# If silence_warnings is available (which suppresses any output to the console) then we use it, else don't worry warnings
# and continue to run it anyway. Should be used within the block of <tt>configure_environment</tt>
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

# Takes a block of <tt>set_constant</tt> declarations, executes it, then reloads the routes
# (this method is used to setup Kete without running through the setup process)
def configure_environment(&block)
  yield(block)
  # Reload the routes based on the current configuration
  ActionController::Routing::Routes.reload!
end
