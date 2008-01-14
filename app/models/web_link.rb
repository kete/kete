class WebLink < ActiveRecord::Base
  # all the common configuration is handled by this module
  include ConfigureAsKeteContentItem

  validates_presence_of :url
  validates_uniqueness_of :url, :case_sensitive => false
  validates_http_url :url
end
