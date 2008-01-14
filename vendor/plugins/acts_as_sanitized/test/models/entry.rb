class Entry < ActiveRecord::Base
  belongs_to :person
  has_many :comments
  
  # specify which fields to sanitize, purposefully excluding 'extended' for testing purposes
  acts_as_sanitized :fields => ['title', 'body']
end
