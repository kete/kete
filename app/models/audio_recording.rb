class AudioRecording < ActiveRecord::Base
  # this is where we handled "related to"
  has_many :content_item_relations, :as => :related_item, :dependent => :destroy
  has_many :topics, :through => :content_item_relations

  # a virtual attribute that holds the audio_item's entire content (sans binary file)
  # as xml formated how we like it
  # for use by acts_as_zoom virtual_field_name, :raw => true
  # this virtual attribue will be populated/updated in our controller
  # in create and update
  # i.e. before save, which triggers our acts_as_zoom record being shot off to zebra
  attr_accessor :oai_record
  acts_as_zoom :fields => [:oai_record], :save_to_public_zoom => ['localhost', 'public'], :raw => true

  acts_as_versioned
  validates_presence_of :title, :path, :filename
  # this may change
  validates_uniqueness_of :title
  # TODO: add validation that prevents markup in short_summary
  # globalize stuff, uncomment later
  # translates :title, :description

  has_attachment :storage => :file_system, :file_system_path => 'private', :content_type => ['audio/mpeg', 'audio/x-mpegurl', 'audio/x-wav', 'application/ogg']
  validates_as_attachment

end
