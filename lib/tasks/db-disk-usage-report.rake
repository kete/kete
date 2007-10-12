# lib/tasks/db_disk_usage_report.rake
#
# Walter McGinnis, 2007-10-11
#
# $ID: $
namespace :db do
  desc 'Get the size of the db disk storage. Currently assumes MySQL.'

  task :disk_usage_report => :environment do
    sql  = "show table status"
    ActiveRecord::Base.establish_connection
    base_path = "#{RAILS_ROOT}/db-disk-report.txt"

    total_size = 0

    data = ActiveRecord::Base.connection.select_all(sql)
    data.each do |record|
      total_size += record["Index_length"].to_i + record["Data_length"].to_i
    end

    puts number_to_human_size(total_size)
  end

  # TODO: replace this with include for ActionView::Helpers::NumberHelper definition
  def number_to_human_size(size, precision=1)
    size = Kernel.Float(size)
    case
    when size == 1        : "1 Byte"
    when size < 1.kilobyte: "%d Bytes" % size
    when size < 1.megabyte: "%.#{precision}f KB"  % (size / 1.0.kilobyte)
    when size < 1.gigabyte: "%.#{precision}f MB"  % (size / 1.0.megabyte)
    when size < 1.terabyte: "%.#{precision}f GB"  % (size / 1.0.gigabyte)
    else                    "%.#{precision}f TB"  % (size / 1.0.terabyte)
    end.sub('.0', '')
  rescue
    nil
  end

end
