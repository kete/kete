# frozen_string_literal: true

# To run these specs:
#
#     # ensure you have sample data loaded into kete_horowhenua
#     $ bundle exec rspec --default-path=./horowhenua_spec
#
puts "******************************************************"
puts "RUNNING HOROWHENUA DATA SPECS"
puts ""
puts "* These specs depend on a `kete_horowhenua` database that contains a canonical"
puts "  set of sample data."
puts ""
puts "******************************************************"

ENV["RAILS_ENV"] ||= 'horowhenua'
puts "Current rails enviornment is: #{ENV['RAILS_ENV']}"

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'capybara/rails'
require 'database_cleaner'

# manually load factory_girl
require 'factory_girl'
FactoryGirl.find_definitions

require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist

Dir[Rails.root.join("horowhenua_spec/support/**/*.rb")].each { |f| require f }

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

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
