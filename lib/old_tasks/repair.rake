# James - 2008-09-12

# Rake tasks to repair Kete data to ensure integrity

namespace :kete do
  namespace :repair do
    # Run all tasks
    task all: [
      'kete:repair:fix_topic_versions',
      'kete:repair:set_missing_contributors',
      'kete:repair:correct_thumbnail_privacies',
      'kete:repair:correct_site_basket_roles',
      'kete:repair:extended_fields']

    desc 'Fix invalid topic versions (adds version column value or prunes on a case-by-case basis.'
    task fix_topic_versions: :environment do
      # This task repairs all Topic::Versions where #version is nil. This is a problem because it causes
      # exceptions when visiting history pages on items.

      pruned, fixed = 0, 0

      # First, find all the candidate versions
      Topic::Version.find(:all, conditions: ['version IS NULL'], order: 'id ASC').each do |topic_version|
        topic = topic_version.topic

        # Skip any problem topics
        next unless topic.version > 0

        # Find all existing versions
        existing_versions = topic.versions.map { |v| v.version }.compact

        # Find the maximum version
        max = [topic.version, existing_versions.max].compact.max

        # Find any versions that are missing from the range of versions we expect to find,
        # given the maximum version we found above..
        missing = (1..max).detect { |v| !existing_versions.member?(v) }

        if missing

          # The current topic_version has no version attribute, and there is a version missing from the set.
          # Therefore, the current version is likely the missing one.

          # Set the version on this topic_version to the missing one..

          topic_version.update_attributes!(
            version: missing,
            version_comment: topic_version.version_comment.to_s + ' NOTE: Version number fixed automatically.'
          )

          print "Fixed missing version for Topic with id = #{topic_version.topic_id} (version #{missing}).\n"
          fixed = fixed + 1

        elsif topic.versions.size > max

          # There are more versions than we expected, and there are no missing version records.
          # So, this version must be additional to requirements. We need to remove the current topic_version.

          # Clean up any flags/tags
          topic_version.flags.clear
          topic_version.tags.clear

          # Check the associations have been cleared
          topic_version.reload

          raise 'Could not clear associations' if \
            topic_version.flags.size > 0 || topic_version.tags.size > 0

          # Prune if we're still here..
          topic_version.destroy

          print "Deleted invalid version for Topic with id = #{topic_version.topic_id}.\n"
          pruned = pruned + 1

        end
      end

      print "Finished. Removed #{pruned} invalid topic versions.\n"
      print "Finished. Fixed #{fixed} topic versions with missing version attributes.\n"
    end

    desc 'Set missing contributors on topic versions.'
    task set_missing_contributors: :environment do
      fixed = 0

      # This rake task runs through all topic_versions and adds a contributor/creator to any
      # which are missing them.

      # This is done because a missing contributor results in exceptions being raised on the
      # topic history pages.

      Topic::Version.find(:all).each do |topic_version|
        # Check that this is a valid topic version.
        next if topic_version.version.nil?

        # Identify any existing contributors for the current topic_version and skip to the next
        # if existing contributors are present.

        sql = <<-SQL
          SELECT COUNT(*) FROM contributions
            WHERE contributed_item_type = "Topic"
            AND contributed_item_id = #{topic_version.topic.id}
            AND version = #{topic_version.version};
        SQL

        next unless Contribution.count_by_sql(sql) == 0

        # Add the admin user as the contributor and add a note to the version comment.

        Contribution.create(
          contributed_item: topic_version.topic,
          version: topic_version.version,
          contributor_role: topic_version.version == 1 ? 'creator' : 'contributor',
          user_id: 1
        )

        topic_version.update_attribute(:version_comment, topic_version.version_comment.to_s + ' NOTE: Contributor added automatically. Actual contributor unknown.')

        print "Added contributor for version #{topic_version.version} of Topic with id = #{topic_version.topic.id}.\n"
        fixed = fixed + 1
      end

      print "Finished. Added contributor to #{fixed} topic versions.\n"
    end

    desc 'Copies incorrectly located uploads to the correct location'
    task correct_upload_locations: :environment do
      # Display a warning to the user, since we're copying files around on the file system
      # and there is a possibility of overwriting something important.

      puts "\n/!\\ IMPORTANT /!\\\n\n"
      puts 'This task will copy files from audio_recordings/ into audio/, and videos/ into video/, '
      puts "where they should be stored.\n\n"

      puts "You should only run this once, to avoid overwriting files.\n\n"

      puts 'Please ensure you have backed up your application directory before continuing. If you '
      puts "have not done this, press Ctrl+C now to abort. Otherwise, press any key to continue.\n\n"

      puts 'Press any key to continue, or Ctrl+C to abort..'
      STDIN.gets
      puts 'Running.. please wait..'

      # A list of folders to copy files between

      copy_directives = {
        'audio_recordings' => 'audio',
        'videos' => 'video'
      }

      # Do this in the context of both public and private files

      %w[public private].each do |privacy_folder|
        copy_directives.each_pair do |src, dest|
          from  = File.join(RAILS_ROOT, privacy_folder, src, '.')
          to    = File.join(RAILS_ROOT, privacy_folder, dest)

          # Skip if the wrongly named folder doesn't exist
          next unless File.exist?(from)

          # Make the destination folder if it does not exist
          # Also detects symlinks, so should be Capistrano safe.
          FileUtils.mkdir(to) unless File.exist?(to)

          # Copy and report what's going on
          print "Copying #{from.gsub(RAILS_ROOT, "")} to #{to.gsub(RAILS_ROOT, "")}.."
          FileUtils.cp_r(from, to)
          print " Done.\n"
        end
      end

      Rake::Task['kete:repair:check_uploaded_files'].invoke
    end

    desc 'Check uploaded files for accessibility'
    task check_uploaded_files: :environment do
      puts "Checking files.. please wait.\n\n"

      inaccessible_files = [AudioRecording, Document, ImageFile, Video].collect do |item_type|
        item_type.find(:all).collect do |instance|
          instance unless File.exist?(instance.full_filename)
        end
      end.flatten.compact

      if inaccessible_files.empty?
        puts 'All files could be found. No further action required.'
      else
        puts "WARNING: Some files could not be found. See below for details:\n\n"
        inaccessible_files.each do |instance|
          puts "- Missing uploaded file for #{instance.class.name} with ID #{instance.id}."
        end
        puts "\nRun rake kete:repair:correct_upload_locations to relocate files to the correct "
        puts "location.\n\n"

        puts 'If you have used Capistrano to deploy your Kete instance, you may also need to copy'
        puts 'archived files from previous versions of your Kete application, which are saved '
        puts "under 'releases' in your main application folder."
        puts 'See http://kete.net.nz/documentation/topics/show/207 for complete instructions.'
      end
    end

    desc 'Makes sure thumbnails are stored in the correct privacy for their still image'
    task correct_thumbnail_privacies: :environment do
      puts "Getting all private StillImages and their public ImageFiles\n"
      StillImage.all.each do |still_image|
        any_incorrect_thumbnails = false
        if still_image.has_public_version?
          still_image.resized_image_files.find_all_by_file_private(true).each do |image_file|
            any_incorrect_thumbnails = true
            move_image_from_to(image_file, false)
          end
        else
          still_image.resized_image_files.find_all_by_file_private(false).each do |image_file|
            any_incorrect_thumbnails = true
            move_image_from_to(image_file, true)
          end
        end
        puts "Moving thumnails for still image #{still_image.id} to the correct directory." if any_incorrect_thumbnails
      end
    end

    # this is not a standard repair, but useful for some legacy sites with bad attached file privacy setting for specific files
    desc 'Move original files that have been mistakenly made publicly downloadable to private original files, specify still images ids with IDS= or a basket with the still images with BASKET_ID='
    task fix_still_image_originals_privacies: :environment do
      puts "Getting specified StillImages and updating their originals to be file_private\n"
      still_images = Array.new
      if ENV['BASKET_ID']
        basket = Basket.find(ENV['BASKET_ID'])
        still_images = basket.still_images
      else
        ids = ENV['IDS'].to_s.split(',')
        still_images = StillImage.find(ids)
      end
      still_images.each do |still_image|
        any_incorrect_originals = false
        unless still_image.file_private?
          still_image.force_privacy = true
          still_image.file_private = true
          still_image.save_without_revision!
          still_image.image_files.find_all_by_file_private(false).each do |image_file|
            next unless image_file == still_image.original_file
            any_incorrect_originals = true
            move_image_from_to(image_file, true)
          end
        end
        puts "Moving original for still image #{still_image.id} to the correct directory." if any_incorrect_originals
      end
    end

    def move_image_from_to(image_file, to_be_private)
      file_path = image_file.public_filename
      if to_be_private
        from = File.join(RAILS_ROOT, 'public', file_path)
        to = File.join(RAILS_ROOT, 'private', file_path)
      else
        from = File.join(RAILS_ROOT, 'private', file_path)
        to = File.join(RAILS_ROOT, 'public', file_path)
      end
      puts "Moving #{from.gsub(RAILS_ROOT, "")} to #{to.gsub(RAILS_ROOT, "")}"
      FileUtils.mv(from, to, force: true)
      image_file.force_privacy = true
      image_file.file_private = to_be_private
      image_file.save!
    end

    desc 'Correct site basket role creation dates for legacy databases'
    task correct_site_basket_roles: :environment do
      site_basket = Basket.site_basket
      member_role = Role.find_by_name_and_authorizable_type_and_authorizable_id('member', 'Basket', site_basket)
      if member_role # skip this task incase there is no member role in site basket
        puts 'Syncing basket role creation dates with user creation dates'
        user_roles = member_role.user_roles.all(include: :user)
        user_roles.each do |role|
          next if role.created_at == role.user.created_at
          RolesUser.update_all({ created_at: role.user.created_at }, { user_id: role.user, role_id: member_role })
          puts "Updated role creation date for #{role.user.user_name}"
        end
        puts 'Synced basket role creation dates'
      end
    end

    desc 'Run all extended field repair tasks'
    task extended_fields: [
      'kete:repair:extended_fields:legacy_google_map',
      'kete:repair:extended_fields:repopulate_related_items_from_topic_type_choices']

    namespace :extended_fields do
      desc 'Run the legacy google map repair tasks'
      task legacy_google_map: :environment do
        map_types = %w[map map_address]
        map_fields = ExtendedField.all(conditions: ['ftype IN (?)', map_types]).collect { |f| f.label_for_params }
        if map_fields.size > 0
          map_sql = map_fields.collect { |f| "extended_content LIKE '%<#{f}%'" }.join(' OR ')
          each_item_with_extended_fields("(#{map_sql})") do |item|
            original_extended_content = item.extended_content.dup
            map_fields.each do |field|
              begin
                map_data = item.send(field) # replace this with .try() in Rails 2.3
              rescue
                next
              end
              if map_data.present?
                if map_data.is_a?(Array)
                  map_data_as_hash = Hash.new
                  map_data.each do |pair|
                    map_data_as_hash[pair[0]] = pair[1]
                  end
                  map_data = map_data_as_hash
                end

                value = { 
                  'zoom_lvl' => (map_data['zoom_lvl'] || SystemSetting.default_zoom_level.to_s),
                  'no_map' => (map_data['no_map'] || '0'), 'coords' => map_data['coords'] 
                }
                value['address'] = map_data['address'] if map_data['address']
                item.send("#{field}=", value)
              end
            end
            if item.extended_content != original_extended_content
              item.update_attribute(:extended_content, item.extended_content)
            end
          end
        end
      end

      desc 'Repopulate related items from Topic Type choices extended field'
      task repopulate_related_items_from_topic_type_choices: :environment do
        topic_type_extended_fields = ExtendedField.find_all_by_ftype('topic_type')
        if topic_type_extended_fields.size > 0
          any_updated_items = false

          conditions = Array.new
          topic_type_extended_fields.each { |field| conditions << "extended_content LIKE '%<#{field.label_for_params}%'" }

          each_item_with_extended_fields("(#{conditions.join(' OR ')})") do |item|
            topic_type_extended_fields.each do |field|
              values = item.structured_extended_content[field.label_for_params]
              next if values.blank?
              values.each do |value|
                value = value.first if value.is_a?(Array)
                next if value.blank?

                topic_id = value['value'].split('/').last.to_i
                topic = Topic.find(topic_id) if topic_id > 0

                if topic && ContentItemRelation.new_relation_to_topic(topic, item)
                  topic.prepare_and_save_to_zoom
                  item.prepare_and_save_to_zoom
                  any_updated_items = true
                  puts "Added related item between Topic #{topic.id} and #{item.class.name} #{item.id}"
                end
              end
            end
          end

          puts "Please run 'rake tmp:cache:clear' to complete the process." if any_updated_items
        end
      end

      private

      def each_item_with_extended_fields(conditions = nil, &block)
        conditions = "extended_content IS NOT NULL AND extended_content != '' AND #{(conditions || '1=1')}"
        ZOOM_CLASSES.each do |zoom_class|
          zoom_class.constantize.all(conditions: conditions).each do |item|
            yield(item)
          end
        end
      end
    end

    namespace :zebra do
      desc 'Update Zebra hosts to 127.0.0.1 if localhost and ONLY if Debian Lenny/YAZ combination make your Zebra unresponsive. You will likely need to run update_hosts_to_localhost at some point in the future if you upgrade your OS/YAZ.'
      task update_hosts_to_ip: :environment do
        dbs = ZoomDb.find(:all, conditions: { host: 'localhost' })

        # only necessary if localhost specified
        if dbs.size > 0
          dbs.each do |db|
            db.host = '127.0.0.1' if db.host == 'localhost'
            db.save!
          end

          p 'changed zoom db hosts updated to 127.0.0.1'
        else
          p 'no change to zoom db host necessary'
        end
      end

      desc 'Update Zebra hosts to localhost if 127.0.0.1 and ONLY if Debian OS version/YAZ combination make your Zebra unresponsive (i.e. you upgrade to Squeeze).'
      task update_hosts_to_localhost: :environment do
        dbs = ZoomDb.find(:all, conditions: { host: '127.0.0.1' })

        # only necessary if localhost specified
        if dbs.size > 0
          dbs.each do |db|
            db.host = 'localhost' if db.host == '127.0.0.1'
            db.save!
          end
          p 'changed zoom db hosts updated to localhost'
        else
          p 'no change to zoom db host necessary'
        end
      end
    end
  end
end
