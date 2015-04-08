# lib/tasks/db_disk_usage_report.rake
#
# Walter McGinnis, 2007-10-11
namespace :db do
  desc 'Get the size of the db disk storage. Currently assumes MySQL.'
  task :disk_usage_report => :environment do
    sql  = "show table status"
    ActiveRecord::Base.establish_connection
    total_size = 0
    data = ActiveRecord::Base.connection.select_all(sql)
    data.each do |record|
      total_size += record["Index_length"].to_i + record["Data_length"].to_i
    end
    include ActionView::Helpers::NumberHelper
    puts number_to_human_size(total_size)
  end
end
