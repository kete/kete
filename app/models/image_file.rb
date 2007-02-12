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
  has_attachment :storage => :file_system, :content_type => :image, :thumbnails => { :small_sq => [50, 50], :small => '50', :medium => '200>', :large => '400>' }, :max_size => 500.megabyte
  validates_as_attachment

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

end
