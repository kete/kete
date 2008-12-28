# WARNING: The selenium tests require bug fixes and features not in the Webrat gem yet
# To have this pass nicely, clone the webrat repo, and run
#   rake gem
#   rake install_gem
# I'll remove this notice when a new gem version is released

SELENIUM_MODE = true

require File.dirname(__FILE__) + '/../integration/integration_test_helper'
