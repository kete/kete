# Skip the system configuration steps
SKIP_SYSTEM_CONFIGURATION = true

ENV["RAILS_ENV"] = "test"

require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require 'test_help'

def set_constant(constant, value)
  if respond_to?(:silence_warnings)
    silence_warnings do
      Object.send(:remove_const, constant) if Object.const_defined?(constant)
      Object.const_set(constant, value)
    end
  else
    Object.const_set(constant, value)
  end
end

def configure_environment(&block)
  yield(block)

  # Reload the routes based on the current configuration
  ActionController::Routing::Routes.reload!
end


configure_environment do
  require File.join(File.dirname(__FILE__), 'system_configuration_constants.rb')
end

# attempt to load zebra if it isn't already
begin
  zoom_db = ZoomDb.find_by_database_name('public')
  Topic.process_query(:zoom_db => zoom_db, :query => "@attr 1=_ALLRECORDS @attr 2=103 ''")
rescue
  `rake zebra:start`
end

class Test::Unit::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

end

# James - 2008-12-08
# Load webrat for integration tests
require 'webrat/rails'


# Overload the IntegrationTest class to ensure tear down occurs OK.
class ActionController::IntegrationTest
  
  def teardown
    configure_environment do
      require File.join(File.dirname(__FILE__), 'system_configuration_constants.rb')
    end
    super
  end
  
end