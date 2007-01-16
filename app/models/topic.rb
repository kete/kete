class Topic < ActiveRecord::Base
  # this is where the actual content lives
  # using the topic_type_fields associated with this topic's topic_type
  # generate a form
  # the results of the form are stored in a content column for the topic
  # as an xml doc
  # when displaying the topic we pull the xml doc out
  # and make the tag's values available as variables to the template
  belongs_to :topic_type

  # each topic or content item lives in exactly one basket
  belongs_to :basket

  # other points:
  # should be versioned see acts_as_versioned
  # we need to store the topic_type_id
  # we probably want acts_as_commentable or role our own - the question being how one can see comments by commenter
  # see http://blog.caboo.se/articles/2006/02/21/eager-loading-with-cascaded-associations
  # about cascading eager associations, note that patch mentioned is now in edge

  # this is where we handled "related to"
  has_many :content_item_relations, :order => 'position', :dependent => :delete_all
  # by using has_many :through associations we gain some bidirectional flexibility
  # with our polymorphic join model
  # basicaly specifically name the classes on the other side of the relationship here
  # see http://blog.hasmanythrough.com/articles/2006/04/03/polymorphic-through
  has_many :web_links, :through => :content_item_relations, :source => :web_link, :order => 'position'
  has_many :audio_recordings, :through => :content_item_relations, :source => :audio_recording, :order => 'position'
  has_many :videos, :through => :content_item_relations, :source => :video, :order => 'position'
  has_many :still_images, :through => :content_item_relations, :source => :still_image, :order => 'position'
  # topics related to a topic
  has_many :child_related_topics, :through => :content_item_relations, :source => :related_topic, :order => 'position'

  # this is where we handle contributed and created items by users
  has_many :contributions, :as => :contributed_item, :dependent => :delete_all
  # :select => "distinct contributions.role, users.*",
  # creator is intended to be just one, but we need :through functionality
  has_many :creators, :through => :contributions, :source => :user, :order => 'created_at' do
    def <<(user)
      begin
        Contribution.with_scope(:create => { :contributor_role => "creator", :version => 1}) { self.concat user }
      rescue
        logger.debug("what is contrib error: " + $!.to_s)
      end
    end
  end
  has_many :contributors, :through => :contributions, :source => :user, :order => 'created_at' do
    def <<(user)
      # TODO: figure out a better way of getting version
      begin
        Contribution.with_scope(:create => { :contributor_role => "contributor", :version => user.version}) { self.concat user }
      rescue
        logger.debug("what is contrib error: " + $!.to_s)
      end
    end
  end

  # a virtual attribute that holds the topic's entire content
  # as xml formated how we like it
  # for use by acts_as_zoom virtual_field_name, :raw => true
  # this virtual attribue will be populated/updated in our controller
  # in create and update
  # i.e. before save, which triggers our acts_as_zoom record being shot off to zebra
  attr_accessor :oai_record
  attr_accessor :basket_urlified_name
  acts_as_zoom :fields => [:oai_record], :save_to_public_zoom => ['localhost', 'public'], :raw => true, :additional_zoom_id_attribute => :basket_urlified_name

  acts_as_versioned
  validates_xml :content
  validates_presence_of :title
  # this may change
  validates_uniqueness_of :title
  # TODO: add validation that prevents markup in short_summary
  # globalize stuff, uncomment later
  # translates :title, :description, :short_summary, :content
  def xml_attributes
    temp_hash = Hash.from_xml("<dummy_root>#{self.content}</dummy_root>")
    return temp_hash['dummy_root']
  end

  def related_topics
    parent_topics = self.class.find(:all,
                              :joins => "INNER JOIN content_item_relations ON topics.id = content_item_relations.topic_id",
                              :conditions => ["((content_item_relations.related_item_id = :object_id) AND (content_item_relations.related_item_type = :class_name))", { :object_id => self.id, :class_name => self.class.to_s}])
    return parent_topics + self.child_related_topics - [self]
  end
end
