require 'ajax_scaffold'

class Topic < ActiveRecord::Base
  belongs_to :topic_type
  # this is where the actual content lives
  # using the topic_type_fields associated with this topic's topic_type
  # generate a form
  # the results of the form are stored in a content column for the topic
  # as an xml doc
  # when displaying the topic we pull the xml doc out
  # and make the tag's values available as variables to the template

  # other points:
  # should be versioned see acts_as_versioned
  # we need to store the topic_type_id
  # we need the results available for searching, possibly using ferrit
  # see acts_as_ferrit plugin
  # and alternative is to use zebra for searching
  # we will probably want validates_xml plugin for the content column
  # we probably also want acts_as_commentable - the question being how one can see comments by commenter
  # see http://blog.caboo.se/articles/2006/02/21/eager-loading-with-cascaded-associations
  # about cascading eager associations, note that patch mentioned is now in edge
  acts_as_versioned
  validates_xml :content
  validates_presence_of :name_for_url
  validates_uniqueness_of :name_for_url
  # globalize stuff, uncomment later
  # translates :name_for_url, :description
  def xml_attributes
    temp_hash = Hash.from_xml("<dummy_root>#{self.content}</dummy_root>")
    return temp_hash['dummy_root']
  end
end
