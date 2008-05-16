class WebLink < ActiveRecord::Base
  # all the common configuration is handled by this module
  include ConfigureAsKeteContentItem

  validates_presence_of :url
  validates_uniqueness_of :url, :case_sensitive => false
  validates_http_url :url
  
  # Private Item mixin
  include ItemPrivacy::All
  
  # Do not version self.file_private
  non_versioned_fields << "file_private"
  non_versioned_fields << "private_version_serialized"
  
  after_save :store_correct_versions_after_save
  
end
