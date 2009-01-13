# lib/tasks/bootstrap.rake
#
# copied and modified from Mephisto, et. al
# http://rails.techno-weenie.net/forums/2/topics/778
#
# Walter McGinnis (walter@katipo.co.nz), 2006-12-10
#
# $ID: $
namespace :db do
  desc "Load initial datamodel, then fixtures (in db/bootstrap/, but include default set here for ordering purposes) into the current environment's database.  Load specific fixtures using BOOTSTRAP_FIXTURES=x,y"
  task :bootstrap => ['db:drop', 'db:create', 'db:bootstrap:load']
  namespace :bootstrap do

    desc "Going back to VERSION 0 is currently broken for Kete, use db:drop the db:create instead."
    task :rewind => :environment do
      # migrate back to the stone age
      ENV['VERSION'] = '0'
      Rake::Task["db:migrate"].invoke

      # forward, comrades, to the future!
      ENV.delete('VERSION')
      Rake::Task["db:migrate"].invoke
    end

    desc "Migrate clean db (no tables) to current VERSION and load specified or default fixtures for Kete."
    task :load => :environment do
      Rake::Task["db:migrate"].invoke
      require 'active_record/fixtures'
      ActiveRecord::Base.establish_connection
      default_fixtures = "zoom_dbs.yml,topic_types.yml,extended_fields.yml,topic_type_to_field_mappings.yml,baskets.yml,web_links.yml,web_link_versions.yml,users.yml,roles.yml,roles_users.yml,topics.yml,topic_versions.yml,contributions.yml,content_types.yml,content_type_to_field_mappings.yml,system_settings.yml,configurable_settings.yml"
      ENV['BOOTSTRAP_FIXTURES'] ||= default_fixtures
      bootstrap_fixtures = ENV['BOOTSTRAP_FIXTURES'].split(/,/)
      bootstrap_fixtures.each do |fixture_file|
        Fixtures.create_fixtures('db/bootstrap', File.basename(fixture_file, '.*'))
      end
      # Walter McGinnis, 2007-11-01
      # if this is for tests, we would like to also load additional fixtures
      # found under test/fixtures
      # note for this initial implementation we skip fixtures files that are already done via db/bootstrap
      # this is inflexible, but good enough for first cut and solve our current problems
      if ENV['RAILS_ENV'] == 'test'
        # get the list of fixtures found under test/fixtures
        test_fixtures = Dir.glob("#{RAILS_ROOT}/test/fixture*.yml")
        # drop those that are already in bootstrap_fixtures
        test_fixtures = test_fixtures - bootstrap_fixtures
        # load remaining fixtures
        test_fixtures.each do |fixture_file|
          Fixtures.create_fixtures('test/fixtures', File.basename(fixture_file, '.*'))
        end
      end
    end
  end

  # Walter McGinnis, 2007-08-13
  # poaching some tasks that are included in edge rails for creating and dropping dbs based on your enviroment
  # TODO: Pull this after we upgrade from 1.2.3 to a later version of Rails
#   desc 'Creates the databases defined in your config/database.yml (unless they already exist)'
#   task :create => :environment do
#     ActiveRecord::Base.configurations.each_value do |config|
#       begin
#         ActiveRecord::Base.establish_connection(config)
#         ActiveRecord::Base.connection
#       rescue
#         case config['adapter']
#         when 'mysql'
#           @charset   = ENV['CHARSET']   || 'utf8'
#           @collation = ENV['COLLATION'] || 'utf8_general_ci'

#           ActiveRecord::Base.establish_connection(config.merge({'database' => nil}))
#           ActiveRecord::Base.connection.create_database(config['database'], {:charset => @charset, :collation => @collation})
#           ActiveRecord::Base.establish_connection(config)
#         when 'postgresql'
#           # thanks to Sam Vilain at Catalyst
#           # for the pg patch
#           ENV['PGHOST'] ||= config['host']
#           ENV['PGUSER'] ||= config['user']
#           ENV['PGPORT'] ||= config['port']
#           `createdb "#{config['database']}" -E utf8`
#         end
#       end
#     end
#     ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations[RAILS_ENV || 'development'])
#   end

  # desc 'Drops the database for your currenet RAILS_ENV as defined in config/database.yml'
#   task :drop => :environment do
#     config = ActiveRecord::Base.configurations[RAILS_ENV || 'development']
#     case config['adapter']
#     when 'mysql'
#       ActiveRecord::Base.connection.drop_database config['database']
#     when 'sqlite3'
#       FileUtils.rm_f File.join(RAILS_ROOT, config['database'])
#     when 'postgresql'
#       # thanks to Sam Vilain at Catalyst
#       # for the pg patch
#       ActiveRecord::Base.disconnect!
#       ENV['PGHOST'] ||= config['host']
#       ENV['PGUSER'] ||= config['user']
#       ENV['PGPORT'] ||= config['port']
#       `dropdb "#{config['database']}"`
#     end
#   end
end
