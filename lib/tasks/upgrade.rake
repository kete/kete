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
                    'kete:upgrade:add_new_system_settings',
                    'kete:upgrade:change_zebra_password',
                    'kete:upgrade:check_required_software',
                    'kete:upgrade:add_missing_mime_types',
                    'zebra:load_initial_records',
                    'kete:upgrade:update_existing_comments_commentable_private']
  namespace :upgrade do
    desc 'Privacy Controls require that Comment#commentable_private be set.  Update existing comments to have this data.'
    task :update_existing_comments_commentable_private => :environment do
      comment_count = 0
      Comment.find(:all, :conditions => "commentable_private is null").each do |comment|
        comment.commentable_private = false if comment.commentable_private.blank?
        comment.save!
        comment_count += 1
      end
      p "updated " + comment_count.to_s + " existing comments that didn't have privacy set."
    end

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

    desc 'Checks for mimetypes an adds them if needed.'
    task :add_missing_mime_types => ['kete:upgrade:add_octet_stream_and_word_types',
                                     'kete:upgrade:add_aiff_to_audio_recordings',
                                     'kete:upgrade:add_tar_to_documents']

    desc 'Adds application/octet-stream and application/word if needed'
    task :add_octet_stream_and_word_types => :environment do
      ['Document Content Types', 'Video Content Types', 'Audio Content Types'].each do |setting_name|
        setting = SystemSetting.find_by_name(setting_name)
        if setting.push('application/octet-stream')
          p "added octet stream mime type to " + setting_name
        end
        if setting_name == 'Document Content Types'
          if setting.push('application/word')
            p "added application/word mime type to " + setting_name
          end
        end
      end
    end

    desc 'Adds application/x-tar if needed'
    task :add_tar_to_documents => :environment do
      setting = SystemSetting.find_by_name('Document Content Types')
      if setting.push('application/x-tar')
        p "added application/x-tar mime type to " + setting.name
      end
    end

    desc 'Adds audio/x-aiff if needed'
    task :add_aiff_to_audio_recordings => :environment do
      setting = SystemSetting.find_by_name('Audio Content Types')
      if setting.push('audio/x-aiff')
        p "added audio/x-aiff mime type to " + setting.name
      end
    end
  end
end

