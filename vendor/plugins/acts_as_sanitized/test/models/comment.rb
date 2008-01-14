class Comment < ActiveRecord::Base
  belongs_to :entry
  belongs_to :person
  
  # let the plugin figure out which fields can be sanitized
  acts_as_sanitized
end
