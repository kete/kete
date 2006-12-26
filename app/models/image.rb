class Image < ActiveRecord::Base
  # this is where we handled "related to"
  has_many :content_item_relations, :as => :related_item, :dependent => :destroy
  has_many :topics, :through => :content_item_relations

  # a virtual attribute that holds the image's entire content (sans binary file)
  # as xml formated how we like it
  # for use by acts_as_zoom virtual_field_name, :raw => true
  # this virtual attribue will be populated/updated in our controller
  # in create and update
  # i.e. before save, which triggers our acts_as_zoom record being shot off to zebra
  attr_accessor :oai_record
  acts_as_zoom :fields => [:oai_record], :save_to_public_zoom => ['localhost', 'public'], :raw => true

  acts_as_versioned
  validates_presence_of :title
  # this may change
  validates_uniqueness_of :title
  # TODO: add validation that prevents markup in short_summary
  # globalize stuff, uncomment later
  # translates :title, :description

  # image files, including thumbnails
  # are handled by ImageFile model

  # handles file uploads
  # we'll want to adjust the filename to include "...-1..." for each
  # version where "-1" is dash-version number
  # for images this will include thumbnails
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
  has_attachment :storage => :file_system, :content_type => :image, :thumbnail_class => 'ImageThumb', :thumbnails => { :small_sq => [50, 50], :small => '50', :medium => '200>', :large => '400>' }
  validates_as_attachment

  # necessary to trick attachment_fu in creating attachments
  # TODO: is there a way to configure around this
  def parent_id
    @parent_id = nil
  end

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
