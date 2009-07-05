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
        puts "Restarted Application"
      else
        puts "Problem restarting Application."
      end
    end

    desc 'Remove /robots.txt (will rebuild next time a bot visits the page)'
    task :remove_robots_txt => :environment do
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
      puts "config/locales.yml.example copied to config/locales.yml"
    end

    desc 'Overwrite existing locales by copying config/locales.yml.example to config/locales.yml'
    task :set_locales_to_default do
      puts "\n/!\\ WARNING /!\\\n\n"
      puts "This task will replace the existing config/locales.yml file with Kete's default\n"
      puts "Press any key to continue, or Ctrl+C to abort..\n"
      STDIN.gets
      path = "#{RAILS_ROOT}/config/locales.yml"
      File.delete(path) if File.exist?(path)
      Rake::Task["kete:tools:set_locales"].invoke
    end

    desc 'Resets the database and zebra to their preconfigured state.'
    task :reset => ['kete:tools:reset:zebra', 'db:bootstrap']
    namespace :reset do

      desc 'Stops and clears zebra'
      task :zebra => :environment do
        Rake::Task["zebra:stop"].invoke
        Rake::Task["zebra:init"].invoke
        ENV['ZEBRA_DB'] = 'private'
        Rake::Task["zebra:init"].execute(ENV)
      end
    end

    desc 'Resize original images based on current IMAGE_SIZES and add new ones if needed. Does not remove no longer needed ones (to prevent links breaking).'
    task :resize_images => :environment do
      @logger = Logger.new(RAILS_ROOT + "/log/resize_images_#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}.log")

      puts "Resizing/created images based on IMAGE_SIZES..."
      @logger.info "Starting image file resizing."

      # get a list of thumbnail keys
      image_size_keys = IMAGE_SIZES.keys

      # setup some variables for reporting once the task is done
      resized_images_count = 0
      created_images_count = 0

      @logger.info "Looping through parent items"

      # loop over every parent image file
      ImageFile.all(:conditions => ["parent_id IS NULL"]).each do |parent_image_file|

        @logger.info "  Fetched parent image #{parent_image_file.id}"

        # start an array with all thumbnail keys and remove ones as we go through
        missing_image_size_keys = image_size_keys.dup

        # loop over the parent images files children thumbnails
        ImageFile.all(:conditions => ["parent_id = ?", parent_image_file]).each do |child_image_file|

          @logger.info "    Fetched child image #{child_image_file.id}"

          # remove this image files thumbnail key from the missing image size keys array
          # (so we eventually end up with an array of keys that aren't being used)
          missing_image_size_keys = missing_image_size_keys - [child_image_file.thumbnail.to_sym]

          # if this image doesn't need to be changed, skip it
          if image_file_match_image_size?(child_image_file)
            @logger.info "      Child image #{child_image_file.id} does not need resizing"
            next
          end

          # recreate an existing image to new sizes based on the parent (original) file
          resize_image_from_original(child_image_file, parent_image_file.full_filename)

          # increase the amount of resized images
          @logger.info "      Incrementing resizes images count"
          resized_images_count += 1

        end

        # loop over and keys we still have remaining
        @logger.info "    Image sizes keys not yet used: #{missing_image_size_keys.collect { |s| s.to_s }.join(',')}"
        missing_image_size_keys.each do |size|

          @logger.info "    Creating image for thumbnail size #{size}"

          # get the parent filename and attach the size to it for the new filename
          filename = parent_image_file.filename.gsub('.', "_#{size.to_s}.")

          # create a new image file based on the parent (details will be updated later)
          image_file = ImageFile.create!(
            parent_image_file.attributes.merge(
              :id => nil,
              :parent_id => parent_image_file.id,
              :thumbnail => size.to_s,
              :filename => filename
            )
          )
          @logger.info "      Created new image record for #{filename}, id #{image_file.id}"

          # recreate an existing image to new sizes based on the parent (original) file
          resize_image_from_original(image_file, parent_image_file.full_filename)

          # increase the amount of created images
          @logger.info "      Incrementing created images count"
          created_images_count += 1

        end

      end

      # Let the user know how many were resized and how many were created
      puts "Finished. #{resized_images_count} images resized, #{created_images_count} images created."
      @logger.info "Finished image resizing. #{resized_images_count} images resized, #{created_images_count} images created."
    end

    private

    # Checks whether an image file thumbnail size matches any of the IMAGE_SIZES values
    def image_file_match_image_size?(image_file)
      # get what the imags sizes should be
      size_string = IMAGE_SIZES[image_file.thumbnail.to_sym]

      # in the case that IMAGE_SIZES no longer has the sizes for existing image, skip it
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
        image_file.resize_image(img, IMAGE_SIZES[image_file.thumbnail.to_sym])
        image_file.send :destroy_file, image_file.full_filename
        image_file.send :save_to_storage, image_file.full_filename
        # make sure we update the image file size, width, and height based on the new resized image
        image_file.update_attributes!(
          :size => File.size(image_file.full_filename),
          :width => img.columns,
          :height => img.rows
        )
        @logger.info "      Child image record updated"
      end
    end
  end
end
