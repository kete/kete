class SearchSource < ActiveRecord::Base
  validates_presence_of :title
  validates_presence_of :source_type
  validates_presence_of :base_url
  validates_presence_of :limit
  
  cattr_accessor :acceptable_source_types
  @@acceptable_source_types = %w{ feed }
end
