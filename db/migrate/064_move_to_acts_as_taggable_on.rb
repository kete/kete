class MoveToActsAsTaggableOn < ActiveRecord::Migration
  def self.up
    
    # Create the extra required column in taggings
    add_column 'taggings', 'context', :string
    
    # Update existing taggings to have a valid context value. 
    # Existing taggings on main item model records are now of "public_tags" context, 
    # and taggings on item version models are "flags".
    execute("UPDATE taggings SET context = 'public_tags' WHERE context IS NULL AND (taggable_type = \"AudioRecording\" OR taggable_type = \"Document\" OR taggable_type = \"StillImage\" OR taggable_type = \"Topic\" OR taggable_type = \"Video\" OR taggable_type = \"WebLink\" OR taggable_type = \"Comment\")")
    
    execute("UPDATE taggings SET context = 'flags' WHERE context IS NULL AND (taggable_type = \"AudioRecording::Version\" OR taggable_type = \"Document::Version\" OR taggable_type = \"StillImage::Version\" OR taggable_type = \"Topic::Version\" OR taggable_type = \"Video::Version\" OR taggable_type = \"WebLink::Version\" OR taggable_type = \"Comment::Version\")")
    
  end

  def self.down
    remove_column 'taggings', 'context'
  end
end
