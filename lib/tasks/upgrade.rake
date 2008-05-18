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
                    'kete:upgrade:add_new_topics',
                    'kete:upgrade:add_new_web_links',
                    'kete:upgrade:add_tech_admin',
                    'kete:upgrade:add_new_system_settings',
                    'kete:upgrade:change_zebra_password',
                    'kete:upgrade:check_required_software',
                    'kete:upgrade:add_missing_mime_types']
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

        # if there are existing system settings
        # drop id from hash, as we want to determine it dynamically
        # else we want to use the bootstap versions
        setting_hash.delete('id') if SystemSetting.count > 0

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

    desc 'Add any new default topics that are missing from our system.'
    task :add_new_topics => :environment do
      topics_from_yml = YAML.load_file("#{RAILS_ROOT}/db/bootstrap/topics.yml")
      # For each topic from yml
      # check if it's in the db
      # if not, add it
      # system settings have unique names
      topics_from_yml.each do |topic_array|
        topic_hash = topic_array[1]

        # drop id from hash, as we want to determine it dynamically
        topic_hash.delete('id')

        if topic_hash['private'] && !Topic.find(:all, :conditions => 'private_version_serialized != "" OR private_version_serialized IS NOT NULL').any? do |topic|
            topic.private_version do
              topic.title == topic_hash['title']
            end
          end
          topic = Topic.new(topic_hash)
          topic.save_without_saving_private!
          topic.creator = User.find(:first)

          # Store the private version and create a blank public version
          topic.send(:store_correct_versions_after_save)

          p "added topic " + topic_hash['title'] + ' with an id of ' + topic.id.to_s
        end
      end
    end

    desc 'Add any new default weblinks that are missing from our system.'
    task :add_new_web_links => :environment do
      web_link_from_yml = YAML.load_file("#{RAILS_ROOT}/db/bootstrap/web_links.yml")
      # For each topic from yml
      # check if it's in the db
      # if not, add it
      # system settings have unique names
      web_link_from_yml.each do |web_link_array|
        web_link_hash = web_link_array[1]

        # drop id from hash, as we want to determine it dynamically
        web_link_hash.delete('id')

        # raise web_link_hash.inspect

        if web_link_hash['private'] == true && !WebLink.find(:all, :conditions => 'private_version_serialized != "" AND private_version_serialized IS NOT NULL').any? do |web_link|
            web_link.private_version do
              web_link.title == web_link_hash['title']
            end
          end
          web_link = WebLink.new(web_link_hash)
          web_link.do_not_moderate = true
          web_link.save_without_saving_private!
          web_link.creator = User.find(:first)

          # Need two versions.
          web_link.do_not_moderate = true
          web_link.save_without_saving_private!
          web_link.add_as_contributor(User.find(:first), web_link.version)

          # Store the private version and create a blank public version
          web_link.send(:store_correct_versions_after_save)

          p "added web_link " + web_link_hash['title'] + ' with an id of ' + web_link.id.to_s
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

    desc 'Change zebra password file to use clear text since encrypted is broken.'
    task :change_zebra_password => :environment do
      ENV['ZEBRA_PASSWORD'] = ZoomDb.find(1).zoom_password
      Rake::Task['zebra:stop'].invoke
      Rake::Task['zebra:set_keteaccess'].invoke
      Rake::Task['zebra:start'].invoke
      p "changed zebra password file"
    end

    desc 'This checks for missing required software and installs it if possible.'
    task :check_required_software => :environment do
      include RequiredSoftware
      required_software = load_required_software
      missing_software = { 'Gems' => missing_libs(required_software), 'Commands' => missing_commands(required_software)}
      p "you have the following missing gems (you might want to do rake prep_app first): #{missing_software['Gems'].inspect}" if !missing_software['Gems'].blank?
      p "you have the following missing external software (take steps to install them before starting your kete server): #{missing_software['Commands'].inspect}" if !missing_software['Commands'].blank?
    end

    desc 'Checks the for mimetype of application/octet-stream'
    task :add_missing_mime_types => :environment do
        octet_file_types = ['Document Content Types', 'Video Content Types', 'Audio Content Types']
        octet_file_types.each do |octet_type|
           setting = SystemSetting.find_by_name(octet_type)
           if !setting.value.include? 'application/octet-stream'
              setting.value = setting.value.gsub(']', ", 'application/octet-stream']")
              p "added octet stream mime type to " + octet_type
           end
           if octet_type == 'Document Content Types'
              if !setting.value.include? 'application/word'
                 setting.value = setting.value.gsub(']', ", 'application/word']")
                 p "added application/word mime type to " + octet_type
              end
           end
           setting.save
        end

    end
  end
end

