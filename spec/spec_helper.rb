# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'database_cleaner'

require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  # config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # config.before(:suite) do
  #   DatabaseCleaner.strategy = :transaction
  # end

  # JS enabled specs happen in a separate process (with a separate DB
  # connection) to the app. We turn off cleaning for them because the changes
  # they make were not made in our transaciton so rolling back has no effect.
  # Basically they have to clean up after themselves.
  # config.before(:each, :js => true) do
  #   DatabaseCleaner.strategy = nil
  # end
  #
  # config.before(:each) do
  #   puts "starting databascleaner"
  #   DatabaseCleaner.start
  # end
  #
  # config.after(:each) do
  #   puts "running databaseclean.clean"
  #   DatabaseCleaner.clean
  # end

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
end



# Capybara runs Javascript enabled specs run in a separate process which gets a
# separate DB connection by default. Using multiple connections is quicker and
# is easy to manage provided that your test database can be emptied between
# runs. We are in an unusual situation where we have a test DB with a lot of
# data so we resort to this old-school hack from:
# http://blog.plataformatec.com.br/2011/12/three-tips-to-improve-the-performance-of-your-test-suite/

class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection
