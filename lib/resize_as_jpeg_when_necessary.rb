# from http://blog.airbladesoftware.com/2007/6/27/compressing-images-with-attachment_fu-and-rmagick
# and http://blog.airbladesoftware.com/2008/1/15/converting-image-format-when-thumbnailing
# modified to use more standard tools, i believe there was some unnecessary code in here
# basically, i'm running on the assumption that if the original is not jpeg, gif, or png
# we should convert it to jpeg
# this obviously is deeply dependent on use of AttachmentFu plugin with Rmagick
module ResizeAsJpegWhenNecessary
  unless included_modules.include? ResizeAsJpegWhenNecessary

    def self.included(klass)
      klass.send :set_callback, :before_thumbnail_saved, :before do |record|
        record.content_type = 'image/jpeg' if record.class.should_be_converted?(record.parent.filename)
      end
      klass.extend(ClassMethods)
    end

    module ClassMethods
      # https://github.com/kete/attachment_fu/blob/master/lib/technoweenie/attachment_fu.rb#L190
      #   * attachment_fu limits image content types to too narrow a view - we
      #     make it match what the user has set as configuration.
      #   * CAREFUL: There is both an instance method and class method named `image?` in that file.
      def image?(content_type)
        allowed_content_types = attachment_options[:content_type]
        if allowed_content_types.include?(:image)
          allowed_content_types.delete(:image)
          allowed_content_types += Technoweenie::AttachmentFu.content_types
        end
        content_type_parts = content_type.split('/')
        format = content_type_parts[1].upcase
        allowed_content_types.include?(content_type) && rmagick_can_read_format?(format)
      end

      # Not in attachment_fu
      def should_be_converted?(name)
        ext = File.extname(name).delete('.')
        # we leave along formats that make thumbnails fine themselves
        !%w(gif jpg jpeg png).include?(ext.downcase) && rmagick_can_read_extension?(ext)
      end

      # Not in attachment_fu
      def rmagick_can_read_extension?(extension)
        extension = 'tiff' if extension == 'tif'
        rmagick_can_read_format? extension.upcase
      end

      # Not in attachment_fu
      def rmagick_can_read_format?(format)
        code = Magick.formats[format]
        # Magick.formats[format] returns a 4 character code that represents what ImageMagick can do with the file
        # char 1: * if it has "native blob support" for that filetype, <space> otherwise
        # char 2: r if it can read this file, - otherwise
        # char 3: w if it can read this file, - otherwise
        # char 4: + if it put multiple images into a single image e.g. animated gif
        return false if code.nil?
        code[1] == 'r'
      end
    end

    # Instance Methods
    # ################

    # https://github.com/kete/attachment_fu/blob/master/lib/technoweenie/attachment_fu/processors/rmagick_processor.rb#L41
    def resize_image(img, size)
      img.strip! unless attachment_options[:keep_profile] # remove metadata from the resized image
      img.format = 'JPEG' # set format to JPEG
      temp_paths.unshift write_to_temp_file(img.to_blob { self.format = 'JPEG' }) if self.class.should_be_converted?(img.format)
      super
    end

    # https://github.com/kete/attachment_fu/blob/master/lib/technoweenie/attachment_fu.rb#L299
    def thumbnail_name_for(thumbnail = nil)
      name = super
      # if this not the original and should be converted to a jpeg
      # check if the name has a thumbnail naming pattern in it
      # rather than hardcode the pattern, we derive it from attachment_fu's thumbnails setting
      if self.class.should_be_converted?(name)
        attachment_options[:thumbnails].keys.each do |key|
          if name.include?('_' + key.to_s)
            name.sub!(/\.\w+$/, '.jpg')
            break
          end
        end
      end
      name
    end

  end
end
