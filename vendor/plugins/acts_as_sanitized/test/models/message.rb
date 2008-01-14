class Message < ActiveRecord::Base
  belongs_to :person
  
  # leave out plugin to test that it doesn't intefere with other models
end
