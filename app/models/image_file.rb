class ImageFile < ActiveRecord::Base
  # this is the class for different sized versions of an image
  # including the original of the file
  # the Image class is for the image meta data
  # although each version's dimension's and filename are stored here
  # not that where parent_id is nil = the original of the file
  belongs_to :still_image

  # handles file uploads
  # this will require overriding full_filename method locally
  # processor none means we don't have to load expensive image manipulation
  # dependencies that we don't need
  # :file_system_path => "#{BASE_PRIVATE_PATH}/#{self.table_name}",
  # will rework with when we get to public/private split
  # Rmagick is default processor for thumbnails
  # TODO: we may want better square cropping via overriding resize_image
  # from vendor/plugins/attachment_fu/lib/technoweenie/attachment_fu/processors/rmagick.rb
  # locally, or possibly by image_science later
  # TODO: have all files converted to jpegs, possibly done by changing filename of thumbnails
  # i.e. should just mean that you replace source extension suffix with desired suffix (.jpg)
  # in the saved filename
  # we use image_thumbs for our resized images
  # so we that on save for each resized version, we don't get a call to acts_as_zoom
  # :file_system_path => "public/images",
  has_attachment :storage => :file_system,
  :content_type => IMAGE_CONTENT_TYPES, :thumbnails => IMAGE_SIZES,
  :max_size => MAXIMUM_UPLOADED_FILE_SIZE

  validates_as_attachment

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
      errors.add attr_name, I18n.t('image_file_model.not_acceptable') unless enum.nil? || enum.include?(send(attr_name))
    end
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
        :file_private             => self.item_private # <- attr_accessor, not a model attribute

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
