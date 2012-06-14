class WebLink < ActiveRecord::Base
  # all the common configuration is handled by this module
  include ConfigureAsKeteContentItem

  # some web sites will always refuse our url requests
  # allow the user to say that the url is definitely valid
  attr_accessor :force_url

  validates_presence_of :url
  validates_uniqueness_of :url, :case_sensitive => false
  validates_http_url :url, :unless => :force_url
  
  # Private Item mixin
  include ItemPrivacy::All
  
  # Do not version self.file_private
  self.non_versioned_columns << "file_private"
  self.non_versioned_columns << "private_version_serialized"
  
  # acts as licensed but this is not versionable (cant change a license once it is applied)
  acts_as_licensed
  
  after_save :store_correct_versions_after_save
end
