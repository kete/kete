# lib/tasks/upgrade.rake
#
# mainly checks that the system settings we need for the new code
# are in the db, if not adds them to db
#
# Walter McGinnis, 2008-01-15
#
namespace :kete do
  desc "Do everything that we need done, like adding data to the db, for an upgrade."
  task :upgrade => ['kete:upgrade:add_new_baskets',
                    'kete:upgrade:add_tech_admin',
                    'kete:upgrade:add_new_system_settings']
  namespace :upgrade do
    desc 'Add the new system settings that are missing from our system.'
    task :add_new_system_settings => :environment do
      system_settings_from_yml = YAML.load_file("#{RAILS_ROOT}/db/bootstrap/system_settings.yml")

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

    desc 'Add any new default baskets that are missing from our system.'
    task :add_new_baskets => :environment do
      baskets_from_yml = YAML.load_file("#{RAILS_ROOT}/db/bootstrap/baskets.yml")
      # For each basket from yml
      # check if it's in the db
      # if not, add it
      # system settings have unique names
      admin_user = User.find(1)
      baskets_from_yml.each do |basket_array|
        basket_hash = basket_array[1]

        # drop id from hash, as we want to determine it dynamically
        basket_hash.delete('id')

        if !Basket.find_by_name(basket_hash['name'])
          basket = Basket.create!(basket_hash)
          basket.accepts_role('admin', admin_user)
          p "added " + basket_hash['name']
        end
      end
    end

    desc 'Add tech_admin role if it is missing from our system.'
    task :add_tech_admin => :environment do
      roles_from_yml = YAML.load_file("#{RAILS_ROOT}/db/bootstrap/roles.yml")

      admin_user = User.find(1)
      tech_admin_hash = roles_from_yml['tech_admin']
      if !Role.find_by_name('tech_admin')
        Role.create!(tech_admin_hash)
        admin_user.has_role('tech_admin', Basket.find(1))
        p "added " + tech_admin_hash['name']
      end
    end
  end
end

