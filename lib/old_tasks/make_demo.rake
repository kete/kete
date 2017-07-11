# lib/tasks/make_demo.rake
#
# use demo-data to create a demo version of kete
#
# Walter McGinnis (walter@katipo.co.nz), 2007-01-26
#
# $ID: $
# TODO: add tasks to rebuild zebra indexes based on data from fixtures
# TODO: add tasks to copy directories for item types to public
namespace :db do
  task make_demo: ['db:bootstrap:rewind', 'db:make_demo:load']
  namespace :make_demo do
    desc "Load initial datamodel, then fixtures (in demo-data/fixtures/*.yml) into the current environment's database.  Load specific fixtures using FIXTURES=x,y
          Defaults to development database.  Set RAILS_ENV to override."

    task load: :environment do
      require 'active_record/fixtures'
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
      (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'demo-data', 'fixtures', '*.{yml,csv}'))).each do |fixture_file|
        Fixtures.create_fixtures('demo-data/fixtures', File.basename(fixture_file, '.*'))
      end
    end
  end
end
