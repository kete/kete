class Review < ActiveRecord::Base
  belongs_to :person
  
  # pass strip_html option and specify fields for testing purposes
  acts_as_sanitized :strip_tags => true, :fields => ['title', 'body']
end
