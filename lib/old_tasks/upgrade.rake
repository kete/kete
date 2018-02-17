# lib/tasks/upgrade.rake
#
# mainly checks that the system settings we need for the new code
# are in the db, if not adds them to db
#
# Walter McGinnis, 2008-01-15
#
namespace :kete do
  desc 'Do everything that we need done, like adding data to the db, for an upgrade.'
  task upgrade: [
    'kete:upgrade:add_new_baskets',
    'kete:upgrade:add_tech_admin',
    'kete:upgrade:add_new_system_settings',
    'kete:upgrade:add_new_default_topics',
    'kete:upgrade:change_zebra_password',
    'kete:upgrade:check_required_software',
    'kete:upgrade:add_missing_mime_types',
    'kete:upgrade:correct_basket_defaults',
    'kete:upgrade:expire_depreciated_rss_cache',
    'kete:upgrade:set_default_join_and_memberlist_policies',
    'kete:upgrade:make_baskets_approved_if_status_null',
    'kete:upgrade:ignore_default_baskets_if_setting_not_set',
    'zebra:load_initial_records',
    'kete:upgrade:update_existing_comments_commentable_private',
    'kete:tools:remove_robots_txt',
    'kete:upgrade:set_default_locale_for_existing_users',
    'kete:upgrade:ensure_logins_all_valid',
    'kete:upgrade:move_user_name_to_display_and_resolved_name',
    'kete:upgrade:add_basket_id_to_taggings',
    'kete:upgrade:make_baskets_private_notification_do_not_email',
    'kete:upgrade:add_nested_values_to_comments',
    'kete:upgrade:change_inset_to_position',
    'kete:upgrade:set_null_private_only_mappings_to_false',
    'kete:upgrade:set_default_import_archive_set_policy',
    'kete:upgrade:add_missing_users']
  namespace :upgrade do
    desc 'Privacy Controls require that Comment#commentable_private be set.  Update existing comments to have this data.'
    task update_existing_comments_commentable_private: :environment do
      comment_count = 0
      Comment.find(:all, conditions: 'commentable_private is null').each do |comment|
        comment.commentable_private = false if comment.commentable_private.blank?
        comment.save!
        comment_count += 1
      end
      p 'updated ' + comment_count.to_s + " existing comments that didn't have privacy set."
    end

    desc 'Add the new system settings that are missing from our system.'
    task add_new_system_settings: :environment do
      system_settings_from_yml = YAML.load_file("#{RAILS_ROOT}/db/bootstrap/system_settings.yml")

      printed_related_items_notice = false

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

          if setting_hash['name'].include?('Related Items Position')
            # when we upgrade and add these new settings, we want to make sure
            # we mimic behaviour of the site beforehand, so related content
            # should be below and the option to change should be hidden
            case setting_hash['name']
            when 'Related Items Position Default'
              setting_hash['value'] = 'below'
            when 'Hide Related Items Position Field'
              setting_hash['value'] = 'true'
            end

            unless printed_related_items_notice
              puts ''
              puts '- Related Items Position setting -'
              puts "If your existing site content tends to have images or tables in your descriptions of items you'll probably want to keep these settings as they are."
              puts "However, if your content descriptions don't have much of these you will like want to change them to the opposite to take advantage of the improved Related Items interface placement."
              puts ''
              printed_related_items_notice = true
            end
          end

          SystemSetting.create!(setting_hash)
          p 'added ' + setting_hash['name']
        end
      end
    end

    desc 'Add the new default topics that are missing from our Kete installation.'
    task add_new_default_topics: :environment do
      topics_from_yml = YAML.load_file("#{RAILS_ROOT}/db/bootstrap/topics.yml")

      # support for legacy kete installations where basket ids
      # are different from those in topics.yml
      # NOTE: if this gets uses again in another task, move this to a reusable method of its own
      basket_ids = {
        '1' => 1,
        '2' => Basket::HELP_BASKET_ID,
        '3' => Basket::ABOUT_BASKET_ID,
        '4' => Basket::DOCUMENTATION_BASKET_ID,
      }

      # for each topic from yml
      topics_from_yml.each do |topic_array|
        topic_hash = topic_array[1]

        # if there are existing topics
        # drop id from hash, as we want to determine it dynamically
        # else we want to use the bootstap versions
        topic_hash.delete('id') if Topic.count > 0

        # map basket id to Kete's basket id (support for legacy installations)
        topic_hash['basket_id'] = basket_ids[topic_hash['basket_id'].to_s]

        # check if it's in the db by looking for a similar topic title in
        # the basket the topic is intended for, and if not present, add it
        if !Topic.find_by_title_and_basket_id(topic_hash['title'], topic_hash['basket_id'])
          topic = Topic.create!(topic_hash)
          topic.creator = User.first
          topic.save!
          p 'added topic: ' + topic_hash['title']
        end
      end
    end

    desc 'Add any new default baskets that are missing from our system.'
    task add_new_baskets: :environment do
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

        basket_id = 1 if basket_hash['urlified_name'] == 'site'
        basket_id ||= "#{basket_hash['urlified_name']}_basket".upcase.constantize
        if !Basket.find_by_id(basket_id)
          basket = Basket.create!(basket_hash)
          basket.accepts_role('admin', admin_user)
          p 'added ' + basket_hash['name']
        end
      end
    end

    desc 'Add tech_admin role if it is missing from our system.'
    task add_tech_admin: :environment do
      roles_from_yml = YAML.load_file("#{RAILS_ROOT}/db/bootstrap/roles.yml")

      admin_user = User.find(1)
      tech_admin_hash = roles_from_yml['tech_admin']
      if !Role.find_by_name('tech_admin')
        Role.create!(tech_admin_hash)
        admin_user.has_role('tech_admin', Basket.find(1))
        p 'added ' + tech_admin_hash['name']
      end
    end

    desc 'Change zebra password file to use clear text since encrypted is broken.'
    task change_zebra_password: :environment do
      ENV['ZEBRA_PASSWORD'] = ZoomDb.find(1).zoom_password
      Rake::Task['zebra:stop'].invoke
      Rake::Task['zebra:set_keteaccess'].invoke
      Rake::Task['zebra:start'].invoke
      p 'changed zebra password file'
    end

    desc 'This checks for missing required software and installs it if possible.'
    task check_required_software: :environment do
      include RequiredSoftware
      required_software = load_required_software
      missing_software = { 'Gems' => missing_libs(required_software), 'Commands' => missing_commands(required_software) }
      p "you have the following missing gems (you might want to do rake prep_app first): #{missing_software['Gems'].inspect}" if !missing_software['Gems'].blank?
      p "you have the following missing external software (take steps to install them before starting your kete server): #{missing_software['Commands'].inspect}" if !missing_software['Commands'].blank?
    end

    desc 'Fix the default baskets settings for unedited baskets so they inherit (like they were intended to)'
    task correct_basket_defaults: :environment do
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
          basket.send(field + '=', standard_basket_defaults[index])
        end
        basket.save!
        p "Corrected settings of #{basket.name} basket"
      end
    end

    desc 'Make Site basket have membership requests closed, and member list visibility at least admin.'
    task set_default_join_and_memberlist_policies: :environment do
      # set some defaults in the site basket
      site_basket = Basket.first # site
      site_basket.set_setting(:basket_join_policy, 'closed') if site_basket.setting(:basket_join_policy).class == NilClass
      site_basket.setting(:memberlist_policy, 'at least admin') if site_basket.setting(:memberlist_policy).class == NilClass
      # if the about, help, or documentation baskets are nil, fill in the same value as the site basket
      Basket.about_basket.set_setting(:basket_join_policy, site_basket.setting(:basket_join_policy)) if Basket.about_basket.setting(:basket_join_policy).class == NilClass
      Basket.help_basket.set_setting(:basket_join_policy, site_basket.setting(:basket_join_policy)) if Basket.help_basket.setting(:basket_join_policy).class == NilClass
      Basket.documentation_basket.set_setting(:basket_join_policy, site_basket.setting(:basket_join_policy)) if Basket.documentation_basket.setting(:basket_join_policy).class == NilClass
    end

    desc 'Make all baskets with the status of NULL set to approved'
    task make_baskets_approved_if_status_null: :environment do
      Basket.all.each do |basket|
        basket.update_attributes!(
                                    status: 'approved',
                                    creator_id: 1
                                  ) if basket.status.blank?
      end
    end

    desc 'Make about, documentation, and help baskets ignore on the site basket recent topics if not done yet.'
    task ignore_default_baskets_if_setting_not_set: :environment do
      Basket.find_all_by_urlified_name(['about', 'documentation', 'help']).each do |basket|
        if basket.setting(:disable_site_recent_topics_display).class == NilClass
          basket.set_setting(:disable_site_recent_topics_display, true)
        end
      end
    end

    desc 'Ensure logins are valid before continuing (1.1 allowed spaces, 1.2 onwards does not).'
    task ensure_logins_all_valid: :environment do
      users = User.all.collect { |user| user.login =~ /\s/ ? user : nil }.compact.flatten
      users.each do |user|
        user.update_attributes!(login: user.login.gsub(/\s/, '_'))
        UserNotifier.deliver_login_changed(user)
        p "Altered login of #{user.user_name}#{" (#{user.login})" if user.login != user.user_name}."
        # we should clear the contribution caches but we don't have access to this method here
        #   expire_contributions_caches_for(user)
      end
    end

    desc 'Transfer the old user names in the extended content fields into the display/resolved name fields on the users table, and remove the user name field mapping for Users'
    task move_user_name_to_display_and_resolved_name: :environment do
      user_count = 0
      User.find(:all, conditions: { resolved_name: '' }).each do |user|
        if user.display_name.blank?
          user_name_field = SystemSetting.extended_field_for_user_name
          extended_content_hash = user.xml_attributes_without_position
          if !extended_content_hash.blank? && !extended_content_hash[user_name_field].blank? && !extended_content_hash[user_name_field]['value'].blank?
            user.display_name = extended_content_hash[user_name_field]['value'].strip
            extended_content_hash = extended_content_hash.delete(user_name_field)
            user.extended_content_values = extended_content_hash
          end
        end
        user.resolved_name = user.login # this will get rewritten using an before save callback on the User model
        user.save!
        user_count += 1
      end
      # finally, lets removing the user name field mapping to prevent new user names from being set
      extended_field = ExtendedField.find_by_label('User Name')
      if extended_field
        content_type_id = ContentType.find_by_class_name('User').id
        extended_field_id = extended_field.id
        content_mapping = ContentTypeToFieldMapping.find_by_content_type_id_and_extended_field_id(content_type_id, extended_field_id)
        content_mapping.destroy unless content_mapping.nil?
      end
      p "#{user_count} users user_name moved to resolved_name" if user_count > 0
    end

    desc 'Give existing users a default locale if they don\'t already have one.'
    task set_default_locale_for_existing_users: :environment do
      User.update_all({ locale: 'en' }, locale: nil)
    end

    desc 'Expire old style page caching for RSS feeds, otherwise they will conflict with new RSS caching system.'
    task expire_depreciated_rss_cache: :environment do
      # needed for zoom_class_controller method
      include ZoomControllerHelpers

      # this is overkill do fully every time upgrade
      # so check if the basket has been previously cached under public
      Basket.find(:all).each do |basket|
        path = RAILS_ROOT + '/public/' + basket.urlified_name
        if File.directory?(path)
          ZOOM_CLASSES.each do |zoom_class|
            # here's the hack way
            # we know RSS feed caches live under "all" or "for" directories
            # actually, just "all" most likely, but taking no chances
            ['all', 'for'].each do |subdir|
              full_path = path + '/' + subdir + '/' + zoom_class_controller(zoom_class)
              next unless File.directory?(full_path)
              # empty the directory files and then delete it
              Dir.glob("#{full_path}/*") do |file|
                File.delete(file)
              end
              Dir.rmdir(full_path)
            end

            # and here's the right way to do it
            # but i was getting this error:
            # private method `chomp' called for #<Hash:0x3e4e744>
            # /Users/walter/Development/apps/kete/vendor/rails/actionpack/lib/action_controller/caching/pages.rb:102:in `page_cache_file'
            # ApplicationController.expire_page(:controller => 'search',
            #                                               :action => 'rss',
            #                                               :urlified_name => basket.urlified_name,
            #                                               :controller_name_for_zoom_class => zoom_class_controller(zoom_class))
          end
          # finally delete the unneeded all and for directories
          ['all', 'for'].each do |subdir|
            full_path = path + '/' + subdir
            next unless File.directory?(full_path)
            Dir.rmdir(full_path)
          end
        end
      end
    end

    desc 'Make site basket default browse type blank, and other baskets inherit'
    task set_default_browse_type: :environment do
      # set some defaults in the site basket
      site_basket = Basket.first # site
      site_basket.set_setting(:browse_view_as, '') if site_basket.setting(:browse_view_as).class == NilClass
      # All other baskets inherit from site
      Basket.all.each do |basket|
        basket.set_setting(:browse_view_as, 'inherit') if basket.setting(:browse_view_as).class == NilClass
      end
    end

    desc 'Add basket id to taggings that dont have a basket id yet'
    task add_basket_id_to_taggings: :environment do
      puts 'Adding Basket ID to Tagging records'
      records = Tagging.all(conditions: { basket_id: nil })
      records.each do |tagging|
        item = tagging.taggable_type.constantize.find_by_id(tagging.taggable_id)
        tagging.update_attribute(:basket_id, item.basket_id) if item
      end
      puts "Added Basket ID to #{records.size} Taggings"
    end

    desc "Make all baskets have private item notification 'do not email' if setting doesn't exist"
    task make_baskets_private_notification_do_not_email: :environment do
      Basket.all.each do |basket|
        basket.set_setting(:private_item_notification, 'do_not_email') if basket.setting(:private_item_notification).blank?
      end
    end

    desc 'Add the parent_id, lft, and rgt values to comments that were created before acts_as_nested_set was put in place'
    task add_nested_values_to_comments: :environment do
      Comment.renumber_all if Comment.count(conditions: { lft: nil }) > 0
    end

    desc 'Migrate from older style related items inset booleans to newer related items position flags'
    task change_inset_to_position: :environment do
      # Use Model.update_all({ changes }, { :id => id }) to get
      # around time consuming validations and possible failures

      conditions = ['related_items_position IS NULL OR related_items_position IN (?)', ['', '0', '1']]
      topics = Topic::Version.all(conditions: conditions)
      topics.each do |topic|
        Topic::Version.update_all(
          {
            related_items_position: (topic.related_items_position.to_i == 1 ? 'inset' : 'below')
          }, id: topic.id
        )
      end

      topics = Topic.all(conditions: conditions)
      topics.each do |topic|
        Topic.update_all(
          {
            related_items_position: (topic.related_items_position.to_i == 1 ? 'inset' : 'below')
          }, id: topic.id
        )
      end

      topics = Topic.all(conditions: "private_version_serialized LIKE '%related_items_inset%'")
      topics.each do |topic|
        private_data = YAML.load(topic.private_version_serialized)
        private_data.each_with_index do |(key, value), index|
          next unless key == 'related_items_inset'
          private_data.delete_at(index)
          private_data << ['related_items_position', (value && value.to_i == 1 ? 'inset' : 'below')]
        end
        private_data = YAML.dump(private_data)
        Topic.update_all({ private_version_serialized: private_data }, id: topic.id)
      end

      inset_default = SystemSetting.find_by_name('Related Items Inset Default')
      if inset_default
        position_default = SystemSetting.find_by_name('Related Items Position Default')
        position_default.update_attribute(:value, (inset_default.value.to_s == 'true' ? 'inset' : 'below'))
        inset_default.destroy
      end

      inset_hidden = SystemSetting.find_by_name('Hide Related Items Inset Field')
      if inset_hidden
        position_hidden = SystemSetting.find_by_name('Hide Related Items Position Field')
        position_hidden.update_attribute(:value, inset_default.value)
        inset_hidden.destroy
      end
    end

    desc 'Set all NULL value private_only values on topic type and content type field mappings to false.'
    task set_null_private_only_mappings_to_false: :environment do
      ContentTypeToFieldMapping.update_all({ private_only: false }, 'private_only IS NULL')
      TopicTypeToFieldMapping.update_all({ private_only: false }, 'private_only IS NULL')
    end

    desc 'Make all baskets import archive set functionality at least member.'
    task set_default_import_archive_set_policy: :environment do
      Basket.all.each do |basket|
        basket.setting(:import_archive_set_policy, 'at least admin') if basket.setting(:import_archive_set_policy).class == NilClass
      end
    end

    desc 'Add any default users that have not been added already.'
    task add_missing_users: :environment do
      users_from_yml = YAML.load(ERB.new(File.read("#{Rails.root}/db/bootstrap/users.yml")).result)

      # for each system_setting from yml
      # check if it's in the db
      # if not, add it
      # system settings have unique names
      users_from_yml.each do |setting_array|
        setting_hash = setting_array[1]

        # we have template values in the hash
        # get the values final form

        # if there are existing system settings
        # drop id from hash, as we want to determine it dynamically
        # else we want to use the bootstap versions
        setting_hash.delete('id') if User.count > 0

        setting_hash.delete('salt')
        setting_hash.delete('crypted_password')

        random_password = ActiveSupport::SecureRandom.hex(8)
        setting_hash[:password] = random_password
        setting_hash[:password_confirmation] = random_password
        setting_hash[:agree_to_terms] = '1'
        setting_hash[:security_code] = true
        setting_hash[:security_code_confirmation] = true

        if !User.find_by_login(setting_hash['login'])
          user = User.create!(setting_hash)
          user.has_role('member', Basket.first)

          p 'added ' + setting_hash['login']
        end
      end
    end

    desc 'Checks for mimetypes an adds them if needed.'
    task add_missing_mime_types: [
      'kete:upgrade:add_octet_stream_and_word_types',
      'kete:upgrade:add_excel_variants_to_documents',
      'kete:upgrade:add_aiff_to_audio_recordings',
      'kete:upgrade:add_tar_to_documents',
      'kete:upgrade:add_open_office_document_types',
      'kete:upgrade:add_jpegs_to_documents',
      'kete:upgrade:add_bmp_to_images',
      'kete:upgrade:add_eps_to_images',
      'kete:upgrade:add_psd_and_gimp_to_images_and_documents',
      'kete:upgrade:add_file_mime_type_variants']

    desc 'Adds psd variants if needed to images and documents'
    task add_psd_and_gimp_to_images_and_documents: :environment do
      ['Document Content Types', 'Image Content Types'].each do |setting_name|
        setting = SystemSetting.find_by_name(setting_name)
        ['image/vnd.adobe.photoshop', 'image/x-photoshop', 'application/x-photoshop', 'image/xcf'].each do |new_type|
          if setting.push(new_type)
            p "added #{new_type} mime type to " + setting.name
          end
        end
      end
    end

    desc 'Adds excel variants if needed'
    task add_excel_variants_to_documents: :environment do
      setting = SystemSetting.find_by_name('Document Content Types')
      ['application/excel', 'application/x-excel', 'application/x-msexcel'].each do |new_type|
        if setting.push(new_type)
          p "added #{new_type} mime type to " + setting.name
        end
      end
    end

    desc 'Adds application/octet-stream and application/word if needed'
    task add_octet_stream_and_word_types: :environment do
      ['Document Content Types', 'Video Content Types', 'Audio Content Types'].each do |setting_name|
        setting = SystemSetting.find_by_name(setting_name)
        if setting.push('application/octet-stream')
          p 'added octet stream mime type to ' + setting_name
        end
        if setting_name == 'Document Content Types'
          if setting.push('application/word')
            p 'added application/word mime type to ' + setting_name
          end
        end
      end
    end

    desc 'Adds application/x-tar if needed'
    task add_tar_to_documents: :environment do
      setting = SystemSetting.find_by_name('Document Content Types')
      if setting.push('application/x-tar')
        p 'added application/x-tar mime type to ' + setting.name
      end
    end

    desc 'Adds jpeg types to documents if needed.  A lot of archive and repository sites call scans to jpeg of a historical document pages.'
    task add_jpegs_to_documents: :environment do
      setting = SystemSetting.find_by_name('Document Content Types')
      ['image/jpeg', 'image/jpg'].each do |type|
        if setting.push(type)
          p "added #{type} mime type to " + setting.name
        end
      end
    end

    desc 'Adds audio/x-aiff if needed'
    task add_aiff_to_audio_recordings: :environment do
      setting = SystemSetting.find_by_name('Audio Content Types')
      if setting.push('audio/x-aiff')
        p 'added audio/x-aiff mime type to ' + setting.name
      end
    end

    desc 'Adds image/bmp if needed to images'
    task add_bmp_to_images: :environment do
      setting = SystemSetting.find_by_name('Image Content Types')
      if setting.push('image/bmp')
        p 'added image/bmp mime type to ' + setting.name
      end
    end

    desc 'Adds eps (application/postscript) if needed to images'
    task add_eps_to_images: :environment do
      setting = SystemSetting.find_by_name('Image Content Types')
      if setting.push('application/postscript')
        p 'added eps (application/postscript) mime type to ' + setting.name
      end
    end

    desc 'Adds OpenOffice document types if needed'
    task add_open_office_document_types: :environment do
      oo_types = [
        'application/vnd.oasis.opendocument.chart',
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
    task add_file_mime_type_variants: :environment do
      new_mime_types = [
        ['Image Content Types', ['image/quicktime', 'image/x-quicktime', 'image/x-ms-bmp']],
        ['Document Content Types', ['application/x-zip', 'application/x-zip-compressed', 'application/x-compressed-tar', 'application/xml']],
        ['Video Content Types',    ['application/flash-video', 'application/x-flash-video', 'video/x-flv', 'video/mp4', 'video/x-m4v', 'video/ogg', 'application/ogg', 'video/theora']],
        ['Audio Content Types',    ['audio/mpg', 'audio/x-mpeg', 'audio/wav', 'audio/x-vorbis+ogg', 'audio/ogg', 'application/ogg', 'audio/vorbis', 'audio/speex', 'audio/flac']]
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
