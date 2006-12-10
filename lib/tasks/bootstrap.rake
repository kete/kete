# lib/tasks/bootstrap.rake
#
# copied and modified from Mephisto, et. al
# http://rails.techno-weenie.net/forums/2/topics/778
#
# Walter McGinnis (walter@katipo.co.nz), 2006-12-10
#
# $ID: $
namespace :db do
  task :bootstrap => ['db:bootstrap:rewind', 'db:bootstrap:load']
  namespace :bootstrap do
    desc "Load initial datamodel, then fixtures (in db/bootstrap/*.yml) into the current environment's database.  Load specific fixtures using FIXTURES=x,y"
    task :rewind => :environment do
      # migrate back to the stone age
      ENV['VERSION'] = '0'
      Rake::Task["db:migrate"].execute

      # forward, comrades, to the future!
      ENV.delete('VERSION')
      Rake::Task["db:migrate"].execute
    end

    task :load => :environment do
      require 'active_record/fixtures'
      ActiveRecord::Base.establish_connection(RAILS_ENV.to_sym)
      (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'db', 'bootstrap', '*.{yml,csv}'))).each do |fixture_file|
        Fixtures.create_fixtures('db/bootstrap', File.basename(fixture_file, '.*'))
      end
    end
  end
end