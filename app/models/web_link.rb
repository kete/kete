class WebLink < ActiveRecord::Base
  # all the common configuration is handled by this module
  include ConfigureAsKeteContentItem

  validates_presence_of :url
  validates_uniqueness_of :url
  # TODO: hunt down problem with this validates false positives
  # validates_http_url :url, :content_type => "text/html"
end
