# lib/tasks/upgrade.rake
#
# mainly checks that the system settings we need for the new code
# are in the db, if not adds them to db
#
# Walter McGinnis, 2008-01-15
#
namespace :kete do
  system_settings_from_yml = YAML.load_file("#{RAILS_ROOT}/db/bootstrap/system_settings.yml")

  desc "Do everything that we need done, like adding data to the db, for an upgrade."
  task :upgrade => ['kete:upgrade:add_new_system_settings']
  namespace :upgrade do
    desc 'Add the new system settings that are missing from our system.'
    task :add_new_system_settings => :environment do

      # for each system_setting from yml
      # check if it's in the db
      # if not, add it
      # system settings have unique names
      system_settings_from_yml.each do |setting_array|
        setting_hash = setting_array[1]

        # drop id from hash, as we want to determine it dynamically
        setting_hash.delete('id')

        if !SystemSetting.find_by_name(setting_hash['name'])
          SystemSetting.create!(setting_hash)
          p "added " + setting_hash['name']
        end
      end
    end
  end
end

