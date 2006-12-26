class ImageThumb < ActiveRecord::Base
  # this is the class for different sized versions of an image
  # besides the original of the file, which is in the image class
  # see image.rb for most of the details
  # belongs_to :image
  # belongs to is done by attachment_fu.rb
  has_attachment :storage => :file_system, :content_type => :image
  validates_as_attachment

end
