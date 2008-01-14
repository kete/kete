class Person < ActiveRecord::Base
  has_many :entries
  
  # pass strip_html option for testing purposes
  acts_as_sanitized :strip_tags => true
end
