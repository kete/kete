# Skip the system configuration steps
SKIP_SYSTEM_CONFIGURATION = true

ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../../config/environment")
require 'test_help'
require File.expand_path(File.dirname(__FILE__) + "/../common_test_methods")
require File.expand_path(File.dirname(__FILE__) + "/../factories")

# James - 2008-12-08
# Load webrat for integration tests
require 'webrat/rails'

# Kieran - 2008-12-09
# Load shoulda for testing
require 'shoulda/rails'

def configure_environment(&block)
  yield(block)
  # Reload the routes based on the current configuration
  ActionController::Routing::Routes.reload!
end

configure_environment do
  require File.join(File.dirname(__FILE__), 'system_configuration_constants.rb')
end

ensure_zebra_running

# Overload the IntegrationTest class to ensure tear down occurs OK.
class ActionController::IntegrationTest
  def teardown
    configure_environment do
      require File.join(File.dirname(__FILE__), 'system_configuration_constants.rb')
    end
    super
  end
end
