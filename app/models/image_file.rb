class ImageFile < ActiveRecord::Base
  # this is the class for different sized versions of an image
  # including the original of the file
  # the Image class is for the image meta data
  # although each version's dimension's and filename are stored here
  # not that where parent_id is nil = the original of the file
  belongs_to :still_image

  # handles file uploads
  # Rmagick is default processor for thumbnails
  # better square cropping via overriding resize_image in plugin in place
  # from vendor/plugins/attachment_fu/lib/technoweenie/attachment_fu/processors/rmagick.rb
  # we also make non-web friendly image files end up with jpegs for resized versions
  # see lib/resize_as_jpeg_when_necessary
  attachment_options = { :storage => :file_system,
    :content_type => IMAGE_CONTENT_TYPES,
    :thumbnails => IMAGE_SIZES,
    :max_size => MAXIMUM_UPLOADED_FILE_SIZE }

  # allow sites to opt-in for keeping embedded metadata from original with resized versions
  if Object.const_defined?('KEEP_EMBEDDED_METADATA_FOR_ALL_SIZES') && KEEP_EMBEDDED_METADATA_FOR_ALL_SIZES
    attachment_options[:keep_profile] = true
  end

  has_attachment attachment_options

  validates_as_attachment

  before_save :width_and_height_present?

  # Modules override various aspects of attachment fu
  # order of includes is important

  include ItemPrivacy::AttachmentFuOverload

  # overriding full_filename to handle our customizations
  # TODO: is this thumbnail arg necessary for classes without thumbnails?
  # def full_filename(thumbnail = nil)
    # file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:file_system_path].to_s
    # this is how this currently reads
    # rails_root/private/images/recording_id/filename
    # TODO: we'll want to make it like this when we add kete (basket) scoping
    # rails_root/private/kete_path_name/images/recording_id/filename
    # File.join(RAILS_ROOT, file_system_path, attachment_path_id, thumbnail_name_for(thumbnail))
  # end

  include ResizeAsJpegWhenNecessary

  include HandleLegacyAttachmentFuPaths

  # custom error message, probably overkill
  # validates the size and content_type attributes according to the current model's options
  def attachment_attributes_valid?
    [:size, :content_type].each do |attr_name|
      enum = attachment_options[attr_name]
      unless enum.nil? || enum.include?(send(attr_name))
        errors.add attr_name, I18n.t("image_file_model.not_acceptable_#{attr_name}",
                                     :max_size => (MAXIMUM_UPLOADED_FILE_SIZE / 1.megabyte))
      end
    end
  end

  def width_and_height_present?
    if width.nil? || width == 0 || height.nil? || height == 0
      errors.add :content_type, I18n.t("image_file_model.unparsable_content_type")
      return false
    end
    true
  end

  # for thumbnail privacy
  attr_accessor :item_private

  # Overload attachment_fu method to ensure file_private is propagated to peers
  def create_or_update_thumbnail(temp_file, file_name_suffix, *size)
    thumbnailable? || raise(ThumbnailError.new("Can't create a thumbnail if the content type is not an image or there is no parent_id column"))
    returning find_or_initialize_thumbnail(file_name_suffix) do |thumb|
      thumb.attributes = {
        :content_type             => content_type,
        :filename                 => thumbnail_name_for(file_name_suffix),
        :temp_path                => temp_file,
        :thumbnail_resize_options => size,

        # Make sure thumbnails are also saved in the context of
        # the still image item privacy
        :file_private             => (self.item_private || false) # <- attr_accessor, not a model attribute

      }
      callback_with_args :before_thumbnail_saved, thumb
      thumb.save!
    end
  end

  def basket
    still_image.basket
  rescue
    nil
  end

end
