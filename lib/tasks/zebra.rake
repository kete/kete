# lib/tasks/zebra.rake
#
# tasks related to setting up and running zebra for kete
#
# Walter McGinnis, 2007-08-11
#
# $ID: $

desc "Tasks related to running the Zebra search index server for Kete"
namespace :zebra do
  desc "Set the kete user password in the zebradb/keteaccess file"
  task :set_keteaccess => :environment do
    `htpasswd -c #{RAILS_ROOT}/zebradb/keteaccess kete #{ENV['ZEBRA_PASSWORD']}`
  end

  desc "Set default zebra databases' ports in zebradb/config/kete-zebra-servers.xml based on a template"
  task :set_ports => :environment do
    ENV['PUBLIC_PORT']

    conf_file_path = "#{RAILS_ROOT}/zebradb/conf/kete-zebra-servers.xml"

    # read in template
    servers_conf_xml = File.read("#{conf_file_path}.template")

    specs = {'private_spec' => "tcp:localhost:#{ENV['PRIVATE_PORT']}",
      'public_spec' => "tcp:@:#{ENV['PUBLIC_PORT']}"}

    specs.each do |spec_name, listen_spec|
      servers_conf_xml = servers_conf_xml.gsub(spec_name, listen_spec)
    end

    # write out new file content
    dest = File.new(conf_file_path,'w+')
    dest << servers_conf_xml
    dest.close
  end

  desc "Initialize a specific Zebra server database.  This will erase any existing data.  Be careful."
  task :init => :environment do
    # have to run the command from inside #{RAILS_ROOT}/zebradb/database_directory
    db = ENV['ZEBRA_DB']
    `cd #{RAILS_ROOT}/zebradb/#{db}; zebraidx -c ../conf/zebra-#{db}.cfg -d #{db} init`
    `cd #{RAILS_ROOT}/zebradb/#{db}; zebraidx -c ../conf/zebra-#{db}.cfg -d #{db} commit`
  end

  desc "Start the Zebra server instance for this Kete"
  task :start => :environment do
    # have to run the command from inside #{RAILS_ROOT}/zebradb
    `cd #{RAILS_ROOT}/zebradb; zebrasrv -f conf/kete-zebra-servers.xml -l ../log/zebra.log -D`
  end

  desc "Choose zebra correct zebra database configuration files for your platform.  I.e. whether the zebra is installed under /usr/local or /opt/local.  Set UNDER=opt or UNDER=usr.  The default configuration files are for /usr/local."
  task :install_location => :environment do
    # have to run the command from inside #{RAILS_ROOT}/zebradb/conf
    %w[ public private ].each do |db|
      `cd #{RAILS_ROOT}/zebradb/conf; cp zebra-#{db}.cfg.#{ENV['UNDER']} zebra-#{db}.cfg`
    end
  end

end
