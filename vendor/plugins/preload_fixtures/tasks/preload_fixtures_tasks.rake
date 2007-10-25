# desc "Explaining what the task does"
# task :preload_fixtures do
#   # Task goes here
# end
# 
# namespace :db do
#   namespace :test do
#     task :preload_fixtures => "db:test:prepare" do
#       puts "PRELOADING FIXTURES..."
#       
#       require 'active_record/fixtures'
#       ActiveRecord::Base.establish_connection(:test)
#       (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir.glob(File.join(RAILS_ROOT, 'test', 'fixtures', '*.{yml,csv}'))).each do |fixture_file|
#         Fixtures.create_fixtures('test/fixtures', File.basename(fixture_file, '.*'))
#       end      
#       
#       puts "DONE"
#     end
#   end
# end
# 
# namespace :test do
#   task :units => "db:test:preload_fixtures"
#   task :functionals => "db:test:preload_fixtures"
#   task :integrations => "db:test:preload_fixtures"
# end