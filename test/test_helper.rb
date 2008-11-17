ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

def set_constant(constant, value)
  if respond_to?(:silence_warnings)
    silence_warnings do
      Object.const_set(constant, value)
    end
  else
    Object.const_set(constant, value)
  end
end

# none of these settings is populated by default
# so we'll set them here to make sure we get results we expect
set_constant('IS_CONFIGURED', true)
set_constant('SITE_NAME', "Test Site")
set_constant('SITE_URL', "http://test.com/")

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


