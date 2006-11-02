require 'ajax_scaffold'

class WebLink < ActiveRecord::Base
  # this is where we handled "related to"
  has_many :content_item_relations, :as => :related_item
  has_many :topics, :through => :content_item_relations

  acts_as_versioned
  validates_presence_of :title, :url
  # this may change
  validates_uniqueness_of :title, :url
  validates_http_url :url
  # TODO: add validation that prevents markup in short_summary
  # globalize stuff, uncomment later
  # translates :title, :description
end
