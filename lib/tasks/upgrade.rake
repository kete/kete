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
                    'kete:upgrade:correct_basket_defaults',
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

    desc 'Fix the default baskets settings for unedited baskets so they inherit (like they were intended to)'
    task :correct_basket_defaults => :environment do
      Basket.all.each do |basket|
        next unless Basket.standard_baskets.include?(basket.id)
        next unless basket.created_at == basket.updated_at

        correctable_fields = ['private_default', 'file_private_default', 'allow_non_member_comments', 'show_privacy_controls']
        current_basket_defaults = correctable_fields.map { |field| basket.send(field) }
        if basket.id == 1 # site basket
          standard_basket_defaults = [false, false, true, false]
        else # other default baskets
          standard_basket_defaults = [nil, nil, nil, nil]
        end

        next if current_basket_defaults == standard_basket_defaults

        correctable_fields.each_with_index do |field, index|
          basket.send(field+"=", standard_basket_defaults[index])
        end
        basket.save
        p "Corrected settings of #{basket.name} basket"
      end
    end

    desc 'Checks for mimetypes an adds them if needed.'
    task :add_missing_mime_types => ['kete:upgrade:add_octet_stream_and_word_types',
                                     'kete:upgrade:add_aiff_to_audio_recordings',
                                     'kete:upgrade:add_tar_to_documents',
                                     'kete:upgrade:add_open_office_document_types',
                                     'kete:upgrade:add_bmp_to_images',
                                     'kete:upgrade:add_eps_to_images',
                                     'kete:upgrade:add_file_mime_type_variants']

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

    desc 'Adds image/bmp if needed to images'
    task :add_bmp_to_images => :environment do
      setting = SystemSetting.find_by_name('Image Content Types')
      if setting.push('image/bmp')
        p "added image/bmp mime type to " + setting.name
      end
    end

    desc 'Adds eps (application/postscript) if needed to images'
    task :add_eps_to_images => :environment do
      setting = SystemSetting.find_by_name('Image Content Types')
      if setting.push('application/postscript')
        p "added eps (application/postscript) mime type to " + setting.name
      end
    end

    desc 'Adds OpenOffice document types if needed'
    task :add_open_office_document_types => :environment do
      oo_types = ['application/vnd.oasis.opendocument.chart',
                  'application/vnd.oasis.opendocument.database',
                  'application/vnd.oasis.opendocument.formula',
                  'application/vnd.oasis.opendocument.drawing',
                  'application/vnd.oasis.opendocument.image',
                  'application/vnd.oasis.opendocument.text-master',
                  'application/vnd.oasis.opendocument.presentation',
                  'application/vnd.oasis.opendocument.spreadsheet',
                  'application/vnd.oasis.opendocument.text',
                  'application/vnd.oasis.opendocument.text-web']

      setting = SystemSetting.find_by_name('Document Content Types')
      oo_types.each do |type|
        if setting.push(type)
          p "added #{type} mime type to " + setting.name
        end
      end
    end
    
    desc 'Adds File mime type variants'
    task :add_file_mime_type_variants => :environment do
      new_mime_types =  [
                          [ 'Image Content Types',    [ 'image/quicktime', 'image/x-quicktime', 'image/x-ms-bmp' ] ],
                          [ 'Document Content Types', [ 'application/x-zip', 'application/x-zip-compressed', 'application/x-compressed-tar' ] ],
                          [ 'Video Content Types',    [ 'application/flash-video', 'application/x-flash-video', 'video/x-flv', 'video/mp4', 'video/x-m4v' ] ],
                          [ 'Audio Content Types',    [ 'audio/mpg', 'audio/x-mpeg', 'audio/wav', 'audio/x-vorbis+ogg' ] ]
                        ]
      new_mime_types.each do |settings|
        setting = SystemSetting.find_by_name(settings.first)
        settings.last.each do |type|
          if setting.push(type)
            p "added #{type} mime type to " + setting.name
          end
        end
      end
    end
  end
end