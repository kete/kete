# lib/tasks/extract_fixtures.rake
#
# copied and modified from
# http://media.pragprog.com/titles/fr_rr/code/CreateFixturesFromLiveData/lib/tasks/extract_fixtures.rake
#
# Walter McGinnis (walter@katipo.co.nz), 2006-12-10
#
# $ID: $
namespace :db do
  desc 'Create YAML fixtures from data in an existing database.
  Default output to test/fixtures, but you can specify another location by
  setting ENV\[\'OUTPUT_FIXTURES_TO_PATH\'\] (no trailing /).

  Defaults to development database.  Set RAILS_ENV to override.'

  # modified to dump to either db/bootstrap or test/fixtures
  task extract_fixtures: :environment do
    sql = 'SELECT * FROM %s'
    skip_tables = ['schema_info']
    ActiveRecord::Base.establish_connection
    (ActiveRecord::Base.connection.tables - skip_tables).each do |table_name|
      i = '000'
      base_path = ENV['OUTPUT_FIXTURES_TO_PATH']

      if base_path.blank?
        base_path = "#{RAILS_ROOT}/test/fixtures"
      end
      File.open("#{base_path}/#{table_name}.yml", 'w') do |file|
        data = ActiveRecord::Base.connection.select_all(sql % table_name)
        file.write data.inject({}) { |hash, record|
          hash["#{table_name}_#{i.succ!}"] = record
          hash
        }.to_yaml
      end
    end
  end
end
