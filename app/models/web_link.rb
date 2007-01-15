class WebLink < ActiveRecord::Base
  # each topic or content item lives in exactly one basket
  belongs_to :basket
  # this is where we handled "related to"
  has_many :content_item_relations, :as => :related_item, :dependent => :destroy
  has_many :topics, :through => :content_item_relations

  # a virtual attribute that holds the web_link's entire content
  # as xml formated how we like it
  # for use by acts_as_zoom virtual_field_name, :raw => true
  # this virtual attribue will be populated/updated in our controller
  # in create and update
  # i.e. before save, which triggers our acts_as_zoom record being shot off to zebra
  attr_accessor :oai_record
  attr_accessor :basket_urlified_name
  acts_as_zoom :fields => [:oai_record], :save_to_public_zoom => ['localhost', 'public'], :raw => true, :additional_zoom_id_attribute => :basket_urlified_name

  acts_as_versioned
  validates_presence_of :title, :url
  # this may change
  validates_uniqueness_of :title, :url
  # TODO: hunt down problem with this validates false positives
  # validates_http_url :url
  # TODO: add validation that prevents markup in short_summary, maybe sanitize?
  # globalize stuff, uncomment later
  # translates :title, :description
end
