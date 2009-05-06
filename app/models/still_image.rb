class StillImage < ActiveRecord::Base

  # image files, including different sized versions of the original
  # are handled by ImageFile model
  has_many :image_files, :dependent => :destroy
  has_one :original_file, :conditions => 'parent_id is null', :class_name => 'ImageFile'
  has_one :thumbnail_file, :conditions => "parent_id is not null and thumbnail = 'small_sq'", :class_name => 'ImageFile'

  # these correspond to sizes in image_file.rb
  IMAGE_SIZES.keys.each do |size|
    has_one "#{size.to_s}_file".to_sym, :conditions => ["parent_id is not null and thumbnail = ?", size.to_s], :class_name => 'ImageFile'
  end

  has_many :resized_image_files, :conditions => 'parent_id is not null', :class_name => 'ImageFile'

  # Each image can only belong to one User's portrait
  has_one :user_portrait_relation, :dependent => :delete
  has_one :portrayed_user, :through => :user_portrait_relation, :source => :user

  # all the common configuration is handled by this module
  # Walter McGinnis, 2008-05-10
  # this has to go after image files for successful basket destroys
  # otherwise still_image_versions rows fail to delete because of order of foreign key constraints
  include ConfigureAsKeteContentItem

  # Private Item mixin
  include ItemPrivacy::All

  # Do not version self.file_private
  self.non_versioned_columns << "file_private"
  self.non_versioned_columns << "private_version_serialized"

  # acts as licensed but this is not versionable (cant change a license once it is applied)
  acts_as_licensed

  after_save :store_correct_versions_after_save

  def self.find_with(size, still_image)
    find(still_image, :include => "#{size}_file".to_sym)
  end

  after_update :update_image_file_locations

  def created_by?(user)
    (self.creator || self.contributors.first) == user
  end

  def is_portrait?
    user_portrait_relation
  end

  include Embedded if ENABLE_EMBEDDED_SUPPORT

  private

  def update_image_file_locations
    unless self.original_file.nil?
      self.original_file.update_attributes({ :file_private => self.file_private })
      self.image_files.reject { |i| i.id == self.original_file.id }.each do |thumb|
        thumb.update_attributes({ :file_private => self.private? })
      end
    end
  end
end
