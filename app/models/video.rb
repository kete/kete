class Video < ActiveRecord::Base
  # each topic or content item lives in exactly one basket
  belongs_to :basket

  # this is where we handled "related to"
  has_many :content_item_relations, :as => :related_item, :dependent => :delete_all
  has_many :topics, :through => :content_item_relations

  # a virtual attribute that holds the video's entire content (sans binary file)
  # as xml formated how we like it
  # for use by acts_as_zoom virtual_field_name, :raw => true
  # this virtual attribue will be populated/updated in our controller
  # in create and update
  # i.e. before save, which triggers our acts_as_zoom record being shot off to zebra
  attr_accessor :oai_record
  attr_accessor :basket_urlified_name
  acts_as_zoom :fields => [:oai_record], :save_to_public_zoom => ['localhost', 'public'], :raw => true, :additional_zoom_id_attribute => :basket_urlified_name

  acts_as_versioned
  validates_presence_of :title
  # this may change
  validates_uniqueness_of :title
  # TODO: add validation that prevents markup in short_summary
  # globalize stuff, uncomment later
  # translates :title, :description

  # handles file uploads
  # we'll want to adjust the filename to include "...-1..." for each
  # version where "-1" is dash-version number
  # for images this will include thumbnails
  # this will require overriding full_filename method locally
  # TODO: add more content_types
  # processor none means we don't have to load expensive image manipulation
  # dependencies that we don't need
  # :file_system_path => "#{BASE_PRIVATE_PATH}/#{self.table_name}",
  # will rework with when we get to public/private split
  has_attachment :storage => :file_system, :file_system_path => "public/video", :content_type => ['application/x-shockwave-flash', 'video/mpeg', 'video/quicktime', 'video/x-msvideo'], :processor => :none
  validates_as_attachment

  # overriding full_filename to handle our customizations
  # TODO: is this thumbnail arg necessary for classes without thumbnails?
  # def full_filename(thumbnail = nil)
    # file_system_path = (thumbnail ? thumbnail_class : self).attachment_options[:file_system_path].to_s
    # this is how this currently reads
    # rails_root/private/videos/recording_id/filename
    # TODO: we'll want to make it like this when we add kete (basket) scoping
    # rails_root/private/kete_path_name/videos/recording_id/filename
    # File.join(RAILS_ROOT, file_system_path, attachment_path_id, thumbnail_name_for(thumbnail))
  # end
end
