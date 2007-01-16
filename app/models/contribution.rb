class Contribution < ActiveRecord::Base
  # this is where we track our polymorphic contributions
  # between users
  # and multiple types of items
  # the user can have multiple contributions
  # for versions
  # or multiple roles
  belongs_to :user
  belongs_to :contributed_item, :polymorphic => true
  # by using has_many :through associations we gain some bidirectional flexibility
  # with our polymorphic join model
  # basicaly specifically name the classes on the other side of the relationship here
  # see http://blog.hasmanythrough.com/articles/2006/04/03/polymorphic-through
  # to track whom created these things
  belongs_to :created_web_link, :class_name => "WebLink", :foreign_key => "contributed_item_id"
  belongs_to :created_audio_recording, :class_name => "AudioRecording", :foreign_key => "contributed_item_id"
  belongs_to :created_video, :class_name => "Video", :foreign_key => "contributed_item_id"
  belongs_to :created_still_image, :class_name => "StillImage", :foreign_key => "contributed_item_id"
  belongs_to :created_topic, :class_name => "Topic", :foreign_key => "contributed_item_id"

  # to track whom contributed to these things
  belongs_to :contributed_web_link, :class_name => "WebLink", :foreign_key => "contributed_item_id"
  belongs_to :contributed_audio_recording, :class_name => "AudioRecording", :foreign_key => "contributed_item_id"
  belongs_to :contributed_video, :class_name => "Video", :foreign_key => "contributed_item_id"
  belongs_to :contributed_still_image, :class_name => "StillImage", :foreign_key => "contributed_item_id"
  belongs_to :contributed_topic, :class_name => "Topic", :foreign_key => "contributed_item_id"

end
