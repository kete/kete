class StillImage < ActiveRecord::Base
  # all the common configuration is handled by this module
  include ConfigureAsKeteContentItem

  # image files, including different sized versions of the original
  # are handled by ImageFile model
  has_many :image_files, :dependent => :destroy
  has_one :original_file, :conditions => 'parent_id is null', :class_name => 'ImageFile'
  has_one :thumbnail_file, :conditions => "parent_id is not null and thumbnail = 'small_sq'", :class_name => 'ImageFile'

  # these correspond to sizes in image_file.rb
  IMAGE_SIZES.keys.each do |size|
    has_one "#{size}_file".to_sym, :conditions => ["parent_id is not null and thumbnail = ?", size], :class_name => 'ImageFile'
  end

  has_many :resized_image_files, :conditions => 'parent_id is not null', :class_name => 'ImageFile'

  def self.find_with(size, still_image)
    find(still_image, :include => "#{size}_file".to_sym)
  end
end
