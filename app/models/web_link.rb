require 'ajax_scaffold'

class WebLink < ActiveRecord::Base
  acts_as_versioned
  validates_presence_of :title
  # this may change
  validates_uniqueness_of :title
  validates_http_url :url
  # TODO: add validation that prevents markup in short_summary
  # globalize stuff, uncomment later
  # translates :title, :description
end
