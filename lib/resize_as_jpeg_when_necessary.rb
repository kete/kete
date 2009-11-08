# from http://blog.airbladesoftware.com/2007/6/27/compressing-images-with-attachment_fu-and-rmagick
# and http://blog.airbladesoftware.com/2008/1/15/converting-image-format-when-thumbnailing
# modified to use more standard tools, i believe there was some unnecessary code in here
# basically, i'm running on the assumption that if the original is not jpeg, gif, or png
# we should convert it to jpeg
# this obviously is deeply dependent on use of AttachmentFu plugin with Rmagick
module ResizeAsJpegWhenNecessary
  unless included_modules.include? ResizeAsJpegWhenNecessary
    # declarations
    def self.included(klass)
      klass.send :before_thumbnail_saved do |record|
        record.content_type = 'image/jpeg' if record.class.should_be_converted?(record.parent.filename)
      end

      klass.extend(ClassMethods)
    end

    module ClassMethods
      def should_be_converted?(name)
        ext = File.extname(name).gsub(".", "")
        # we leave along formats that make thumbnails fine themselves
        !%w( gif jpg jpeg png ).include?(ext.downcase) && rmagick_can_read_extension?(ext)
      end

      def rmagick_can_read_extension?(extension)
        # Convert extensions to ones that RMagick recognises.
        ext = case extension
              when 'tif': 'tiff'
              else extension
              end
        rmagick_can_read_format? ext.upcase
      end

      def rmagick_can_read_format?(format)
        code = Magick.formats[format]
        # Determine whether RMagick knows how to read files in this format.
        # TODO: test native blob support?  p.416 Ruby Cookbook.
        code && code[1] == ?r
      end


      # attachment fu limits image content types to too narrow a view
      # we make it match what the user has set as configuration
      def image?(content_type)
        allowed_content_types = attachment_options[:content_type]
        if allowed_content_types.include?(:image)
          allowed_content_types.delete(:image)
          allowed_content_types += Technoweenie::AttachmentFu.content_types
        end
        content_type_parts = content_type.split("/")
        format = content_type_parts[1].upcase
        allowed_content_types.include?(content_type) && rmagick_can_read_format?(format)
      end
    end

    def resize_image(img, size)
      img.strip! unless attachment_options[:keep_profile] # remove metadata from the resized image
      img.format = 'JPEG' # set format to JPEG
      self.temp_path = write_to_temp_file(img.to_blob { self.format = 'JPEG' }) if self.class.should_be_converted?(img.format)
      super
    end

    def thumbnail_name_for(thumbnail = nil)
      name = super
      # if this not the original and should be converted to a jpeg
      # check if the name has a thumbnail naming pattern in it
      # rather than hardcode the pattern, we derive it from attachment_fu's thumbnails setting
      if self.class.should_be_converted?(name)
        attachment_options[:thumbnails].keys.each do |key|
          if name.include?("_" + key.to_s)
            name.sub!(/\.\w+$/, '.jpg')
            break
          end
        end
      end
      name
    end
  end
end
