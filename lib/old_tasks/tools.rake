# frozen_string_literal: true

# lib/tasks/tools.rake
#
# miscellaneous tools for kete (clearing robots.txt file)
#
# Kieran Pilkington, 2008-10-01
#
namespace :kete do
  namespace :tools do
    desc 'Restart application (Passenger specific)'
    task :restart do
      restart_result = system("touch #{RAILS_ROOT}/tmp/restart.txt")
      if restart_result
        puts 'Restarted Application'
      else
        puts 'Problem restarting Application.'
      end
    end

    desc 'Remove /robots.txt (will rebuild next time a bot visits the page)'
    task remove_robots_txt: :environment do
      path = "#{RAILS_ROOT}/public/robots.txt"
      File.delete(path) if File.exist?(path)
    end

    desc 'Copy config/locales.yml.example to config/locales.yml'
    task :set_locales do
      path = "#{RAILS_ROOT}/config/locales.yml"
      if File.exist?(path)
        puts "ERROR: Locales file already exists. Delete it first or run 'rake kete:tools:set_locales_to_default'"
        exit
      end
      require 'ftools'
      File.cp("#{RAILS_ROOT}/config/locales.yml.example", path)
      puts 'config/locales.yml.example copied to config/locales.yml'
    end

    desc 'Overwrite existing locales by copying config/locales.yml.example to config/locales.yml'
    task :set_locales_to_default do
      puts "\n/!\\ WARNING /!\\\n\n"
      puts "This task will replace the existing config/locales.yml file with Kete's default\n"
      puts "Press any key to continue, or Ctrl+C to abort..\n"
      STDIN.gets
      path = "#{RAILS_ROOT}/config/locales.yml"
      File.delete(path) if File.exist?(path)
      Rake::Task['kete:tools:set_locales'].invoke
    end

    namespace :locales do
      desc 'Make a timestamped copy of specified locale if there are changes from last backup. THIS=[language_code] e.g. rake kete:tools:locales:backup_for THIS=zh'
      task :backup_for do
        locale = ENV['THIS']
        path_stub = "#{Rails.root}/config/locales/"
        path = path_stub + locale + '.yml'
        timestamped_path = path + '.' + Time.now.utc.xmlschema

        unless File.exist?(path)
          puts "ERROR: #{locale} locale doesn't exist."
          exit
        end

        last_backup_filename = Dir.entries(path_stub).select { |entry| entry.include?(locale + '.yml.') }.last

        do_backup = false

        if last_backup_filename.blank?
          do_backup = true
        else
          full_last_backup_filename = path_stub + last_backup_filename

          diff_output = `diff #{path} #{full_last_backup_filename}`

          do_backup = true if diff_output.present?
        end

        if do_backup
          require 'ftools'
          File.cp(path, timestamped_path)
          puts "Backup of #{locale}.yml created."
        else
          puts "No backup needed. Last backup matches current #{locale}.yml."
        end
      end
    end

    desc 'Resets the database and zebra to their preconfigured state.'
    task reset: ['kete:tools:reset:zebra', 'db:bootstrap', 'kete:tools:restart']
    namespace :reset do
      desc 'Stops and clears zebra'
      task zebra: :environment do
        Rake::Task['zebra:stop'].invoke
        Rake::Task['zebra:init'].invoke
        ENV['ZEBRA_DB'] = 'private'
        Rake::Task['zebra:init'].execute(ENV)
      end
    end

    desc 'Resize original images based on current SystemSetting.image_sizes and add new ones if needed. Does not remove no longer needed ones (to prevent links breaking). By default image files that match new sizes will be skipped. If you need new versions recreated even if there is an existing file that matches the size, use FORCE_RESIZE=true.'
    task resize_images: :environment do
      @logger = Logger.new(RAILS_ROOT + "/log/resize_images_#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}.log")

      puts 'Resizing/created images based on SystemSetting.image_sizes...'
      @logger.info 'Starting image file resizing.'

      force_resize = ENV['FORCE_RESIZE'] && ENV['FORCE_RESIZE'] == 'true' ? true : false
      if force_resize
        puts 'All image sizes will be recreated from originals, even if the same size image file already exists.'
        @logger.info 'FORCE_RESIZE=true'
      end

      # get a list of thumbnail keys
      image_size_keys = SystemSetting.image_sizes.keys

      # setup some variables for reporting once the task is done
      resized_images_count = 0
      created_images_count = 0

      @logger.info 'Looping through parent items'

      # loop over every parent image file
      ImageFile.all(conditions: ['parent_id IS NULL']).each do |parent_image_file|
        @logger.info "  Fetched parent image #{parent_image_file.id}"

        # start an array with all thumbnail keys and remove ones as we go through
        missing_image_size_keys = image_size_keys.dup

        # loop over the parent images files children thumbnails
        ImageFile.all(conditions: ['parent_id = ?', parent_image_file]).each do |child_image_file|
          @logger.info "    Fetched child image #{child_image_file.id}"

          # remove this image files thumbnail key from the missing image size keys array
          # (so we eventually end up with an array of keys that aren't being used)
          missing_image_size_keys = missing_image_size_keys - [child_image_file.thumbnail.to_sym]

          # if this image doesn't need to be changed, skip it
          if image_file_match_image_size?(child_image_file) && !force_resize
            @logger.info "      Child image #{child_image_file.id} does not need resizing"
            next
          end

          # recreate an existing image to new sizes based on the parent (original) file
          resize_image_from_original(child_image_file, parent_image_file.full_filename)

          # increase the amount of resized images
          @logger.info '      Incrementing resizes images count'
          resized_images_count += 1
        end

        # loop over and keys we still have remaining
        @logger.info "    Image sizes keys not yet used: #{missing_image_size_keys.collect { |s| s.to_s }.join(',')}"
        missing_image_size_keys.each do |size|
          @logger.info "    Creating image for thumbnail size #{size}"

          # get the parent filename and attach the size to it for the new filename
          filename = parent_image_file.filename.gsub('.', "_#{size}.")

          # create a new image file based on the parent (details will be updated later)
          image_file = ImageFile.create!(
            parent_image_file.attributes.merge(
              id: nil,
              parent_id: parent_image_file.id,
              thumbnail: size.to_s,
              filename: filename
            )
          )
          @logger.info "      Created new image record for #{filename}, id #{image_file.id}"

          # recreate an existing image to new sizes based on the parent (original) file
          resize_image_from_original(image_file, parent_image_file.full_filename)

          # increase the amount of created images
          @logger.info '      Incrementing created images count'
          created_images_count += 1
        end
      end

      # Let the user know how many were resized and how many were created
      puts "Finished. #{resized_images_count} images resized, #{created_images_count} images created."
      @logger.info "Finished image resizing. #{resized_images_count} images resized, #{created_images_count} images created."
    end

    namespace :related_items do
      # ITEM_CLASSES is not available here
      %w(Topic StillImage AudioRecording Video WebLink Document).each do |item_class|
        namespace item_class.tableize.to_sym do
          %w{inset below sidebar}.each do |setting|
            desc "Update all #{item_class.tableize} so that the related items section in each is positioned #{setting}."
            task "position_to_#{setting}" => :environment do
              set_related_items_inset_to(item_class, setting)
              puts "Finished. All #{item_class.tableize} now have their related items #{setting}."
            end
          end
        end
      end

      # Provide an option to make everything a certain type at once
      namespace :all do
        %w{inset below sidebar}.each do |setting|
          desc "Update all item types so that the related items section in each is positioned #{setting}."
          task "position_to_#{setting}" => :environment do
            %w(Topic StillImage AudioRecording Video WebLink Document).each do |item_class|
              set_related_items_inset_to(item_class, setting)
            end
            puts "Finished. All item types now have their related items #{setting}."
          end
        end
      end
    end

    # tools supporting things like data massaging in imports
    namespace :imports do
      desc "Takes a RegExp pattern (no escape \s necessary, but must be wrapped in single quotes) to match and replaces it with either another pattern (also in single quotes), variables (\1, \2, etc.) can be used. File paths to file are relative to Rails.root directory."
      task :replace_pattern_in_file do
        source_file = pwd + '/' + ENV['SOURCE_FILE']

        output_file = File.new(pwd + '/' + ENV['TO_FILE'], 'w+')

        pattern = Regexp.new(ENV['PATTERN'])

        p pattern.inspect

        replacement = ENV['REPLACEMENT']

        p replacement.inspect

        changed_lines_count = 0
        # iterate over each line and apply the substitution
        IO.foreach(source_file) do |line|
          original_line = line

          line = line.gsub(pattern, replacement)
          output_file << line

          changed_lines_count += 1 if original_line != line
        end
        output_file.close

        puts "#{changed_lines_count} lines changed."
      end
    end

    namespace :tiny_mce do
      desc 'Do everything that we need done, like adding data to the db, for an upgrade.'
      task configure_imageselector: [
        'kete:tools:tiny_mce:write_default_imageselector_providers_json',
        'kete:tools:tiny_mce:write_default_imageselector_sizes_json']

      desc 'Write javascripts/image_selector_config/providers.json file that reflects this site. Will replace file if it exists.'
      task write_default_imageselector_providers_json: :environment do
        return unless Kete.is_configured?

        this_site_config = {
          title: SystemSetting.pretty_site_name,
          domain: SystemSetting.site_name,
          oembed_endpoint: SystemSetting.site_url + 'oembed',
          upload_startpoint: {
            label: 'Upload New Image',
            url: SystemSetting.site_url + 'site/images/new?as_service=true&append_show_url=true'
          },
          insertIntoEditor: { editor: 'TinyMCE' },
          sources: [
            {
              name: 'Latest',
              media_type: 'image',
              media_type_plural: 'images',
              url: SystemSetting.site_url + 'site/all/images/rss.xml',
              searchable_stub: false,
              limit_parameter: '?count=',
              display_limit: 4,
              page_parameter: '&page='
            },
            {
              name: 'Search',
              media_type: 'image',
              media_type_plural: 'images',
              url: SystemSetting.site_url + 'site/search/images/for/terms/rss.xml?search_terms=',
              searchable_stub: true,
              limit_parameter: '&count=',
              display_limit: 4,
              page_parameter: '&page='
            }
          ]
        }

        # write out new file content
        conf_file_path = "#{Rails.root}/public/javascripts/image_selector_config/providers.json"
        dest = File.new(conf_file_path, 'w+')
        dest << [this_site_config].to_json
        dest.close
      end

      desc 'Write javascripts/image_selector_config/sizes.json file that reflects this site settings. Will replace file if it exists.'
      task write_default_imageselector_sizes_json: :environment do
        return unless Kete.is_configured?

        this_site_sizes_config = []

        SystemSetting.image_sizes.each do |size_array|
          # decypher imagemagick rules
          width = nil
          height = nil
          specs = size_array.last.split('x')

          width = specs.first.to_i

          if specs.size == 1
            height = 3 * width
          else
            height = specs[1].to_i
          end

          new_size = { 'name' => size_array.first.to_s }
          new_size['width'] = width if width
          new_size['height'] = height if height

          this_site_sizes_config << new_size
        end

        # write out new file content
        conf_file_path = "#{Rails.root}/public/javascripts/image_selector_config/sizes.json"
        dest = File.new(conf_file_path, 'w+')
        dest << this_site_sizes_config.to_json
        dest.close
      end
    end

    # tools for data massaging of existing items
    namespace :topics do
      desc "Given a passed in CONDITIONS string (conditions in sql form), move topics that fit CONDITIONS to TARGET (as specified by passed in id) and also USER for id that should be attributed with the move actions. E.g. 'rake kete:tools:topics:move_to_basket TARGET=6 CONDITIONS=\"topic_type_id = 4\" USER=1'. You can optionally specify whether zoom records should be built progressively with ZOOM=true (false by default). If you have a large number of topics that match CONDITIONS, you may want to alter this task to handle batches (otherwise you risk memory issues). Other thing to keep in mind is that this doesn't currently leave any sort of redirect behind for a moved item. Best done before you have a public site. Also Comments are not currently dealt with here."
      task move_to_basket: :environment do
        to_basket = Basket.find(ENV['TARGET'])
        target_basket_path = to_basket.urlified_name

        # gather topics
        topics = Topic.find(:all, conditions: ENV['CONDITIONS'])

        raise 'No matching topics.' unless topics.size > 0

        user = User.find(ENV['USER'])

        should_rebuild = ENV['ZOOM'].present? && ENV['ZOOM'] == 'true' ? true : false

        raise 'ZOOM option current broken. Feel free to fix and submit a patch!' if should_rebuild

        log_file = "#{Rails.root}/log/move_to_basket_#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}.log"
        @logger = Logger.new(log_file)

        puts "Opened logging in #{log_file}"

        @logger.info('Target basket is:' + to_basket.id.to_s)
        @logger.info("User is: #{user.id} " + user.login)

        relationships_no_change_count = 0
        relationships_changed_count = 0
        topics_moved_count = 0

        topics.each do |topic|
          @logger.info('Topic: ' + topic.id.to_s)

          show_path_stub = '/topics/show/' + topic.id.to_s + '-'
          old_basket = topic.basket
          old_basket_path = old_basket.urlified_name
          old_topic_url_stub = old_basket_path + show_path_stub
          new_topic_url_stub = target_basket_path + show_path_stub

          # changing the basket changes the zoom_id and thus
          # when we go to update the zoom search record
          # it doesn't update the old one, but add a new one
          # zoom_destroy here before zoom_id is changed
          topic.zoom_destroy if should_rebuild

          # update basket_id
          topic.basket = to_basket
          topic.do_not_moderate = true
          topic.version_comment = "Moved from #{old_basket.name} to #{to_basket.name}"

          successful = topic.save

          if successful
            @logger.info('moved topic')

            topic.reload

            topic.add_as_contributor(user, topic.version)

            # split things up into different types
            class_names = ZOOM_CLASSES - ['Topic', 'Comment']

            kinds_to_process = ['child_related_topics'] + ['parent_related_topics'] + class_names.collect { |n| n.tableize }
            kinds_to_process.each do |kind|
              kind_count = topic.send(kind.to_sym).count
              @logger.info("number of related #{kind}: " + kind_count.to_s)
              next if kind_count == 0

              table_name = kind
              table_name = 'topics' if kind.include?('child') || kind.include?('parent')

              clause = "#{table_name}.id >= :start_id"
              clause_values = {}
              clause_values[:start_id] = topic.send(kind.to_sym).find(
                :first,
                order: "#{table_name}.id"
              ).id

              # load up to batch_size results into memory at a time
              batch_count = 1
              batch_size = 500 # 1000 is default in find_in_batches
              last_id = 0

              # find_in_batches messes up oai_record call for some reason, cobblying our own offset system
              kind_count_so_far = 0
              while kind_count > kind_count_so_far
                if kind_count_so_far > 0
                  clause_values[:start_id] = topic.send(kind.to_sym).find(
                    :first,
                    conditions: "#{table_name}.id > #{last_id}",
                    order: "#{table_name}.id"
                  ).id
                end

                related_items = topic.send(kind.to_sym).find(
                  :all,
                  conditions: [clause, clause_values],
                  limit: batch_size,
                  order: "#{table_name}.id"
                )

                @logger.info('number to do in batch: ' + related_items.size.to_s)

                related_items.each do |item|
                  kind_count_so_far += 1
                  # update extended_content references for this topic to new url
                  if item.extended_content.include?(old_topic_url_stub)
                    before = item.extended_content
                    after = before.gsub(old_topic_url_stub, new_topic_url_stub)

                    item.extended_content = after
                    item.do_not_moderate = true
                    item.version_comment = "Updated links to \"#{topic.title}\""

                    item_successful = item.save

                    if item_successful
                      item.reload
                      item.add_as_contributor(user, item.version)

                      # update search record for related item
                      item.prepare_and_save_to_zoom if should_rebuild

                      relationships_changed_count += 1
                    end
                  else
                    relationships_no_change_count += 0
                  end
                  if batch_count < batch_size
                    # track count of where we are in the batch
                    batch_count += 1
                  elsif batch_count == batch_size
                    # reset the next record to first in batch
                    batch_count = 1
                    @logger.info('last_id of batch: ' + item.id.to_s)
                  end
                  last_id = item.id
                end
                if batch_count < batch_size && batch_count != 1
                  batch_count = 1
                  @logger.info('last_id of batch: ' + last_id.to_s)
                end
              end
            end

            topic.prepare_and_save_to_zoom if should_rebuild

            topics_moved_count += 1

          else
            raise "Topic #{topic.id} failed to be moved. Stopping. You may need to rebuild that topic's search record."
          end
        end

        # rebuild search records for queued topics

        @logger.info("#{topics_moved_count} topics moved.")
        @logger.info("#{relationships_no_change_count} relationships no change necessary.")
        @logger.info("#{relationships_changed_count} relationships updated.")

        puts "#{topics_moved_count} topics moved."
        puts "#{relationships_changed_count} relationships updated."
        puts "#{relationships_no_change_count} relationships no change necessary."
      end
    end

    private

    def set_related_items_inset_to(item_class, position)
      # update all items
      item_class.constantize.update_all(related_items_position: position)
      # update all versions of every item
      item_class.constantize::Version.update_all(related_items_position: position)
      # then go through and update the private attributes of any items with them
      each_item_with_private_version(item_class) do |private_data|
        # loop through each key/value array (starts as [[key,value],[key,value]])
        private_data.each_with_index do |(key, value), index|
          # skip this unless we have the right field
          next unless key == 'related_items_position'
          # delete the old data
          private_data.delete_at(index)
          # add in the new data
          private_data << ['related_items_position', position]
        end
      end
    end

    def each_item_with_private_version(item_class, &block)
      # find all items with private version data present, then loop through each
      item_class.constantize.all(conditions: "private_version_serialized IS NOT NULL AND private_version_serialized != ''").each do |item|
        # load the data from YML to an array of key/value arrays (e.g. [[key,value],[key,value]])
        current_data = YAML.load(item.private_version_serialized)
        # yield the block passed in (passing the current data to it) and capture the return data
        changed_data = yield(current_data)
        # dump the changed data into a YAML representation
        private_data = YAML.dump(changed_data)
        # and update the private version serialized field (update_all means we avoid annoying validations)
        item_class.constantize.update_all({ private_version_serialized: private_data }, { id: item.id })
      end
    end

    # Checks whether an image file thumbnail size matches any of the SystemSetting.image_sizes values
    def image_file_match_image_size?(image_file)
      # get what the imags sizes should be
      size_string = SystemSetting.image_sizes[image_file.thumbnail.to_sym]

      # in the case that SystemSetting.image_sizes no longer has the sizes for existing image, skip it
      # TODO: in the future, we want to allow users to specify if image files and db
      # record should be deleted
      return true if size_string.blank?

      # if we have a ! in the size, then both height and width have to match (else only one needs to)
      absolute = size_string.include?('!')

      # if we have a x in the size, then we have both height and width to match (else we have only width)
      sizes = size_string.split('x').collect { |s| s.to_i }

      # do we have width and height?
      if sizes.size > 1
        # do we need to match both width and height?
        if absolute
          # check if the current width and height are what they should be
          sizes[0] == image_file.width &&
            sizes[1] == image_file.height
        else
          # check if the current width or height are what they should be
          sizes[0] == image_file.width ||
            sizes[1] == image_file.height
        end
      else
        # check if the current width is what it should be
        sizes[0] == image_file.width
      end
    end

    # takes an image file and resizes it based on the original file
    # uses attachment_fu method on the ImageFile class and image_file instance
    def resize_image_from_original(image_file, original_file)
      @logger.info "      Resizing child image #{image_file.id} based on #{original_file}"
      ImageFile.with_image original_file do |img|
        image_file.resize_image(img, SystemSetting.image_sizes[image_file.thumbnail.to_sym])
        image_file.send :destroy_file, image_file.full_filename
        image_file.send :save_to_storage, image_file.full_filename
        # make sure we update the image file size, width, and height based on the new resized image
        image_file.update_attributes!(
          size: File.size(image_file.full_filename),
          width: img.columns,
          height: img.rows
        )
        @logger.info '      Child image record updated'
      end
    end
  end
end
