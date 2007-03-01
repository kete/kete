class Topic < ActiveRecord::Base
  # this is where the actual content lives
  # using the extended_fields associated with this topic's topic_type
  # generate a form
  # the results of the form are stored in a extended_content column for the topic
  # as an xml doc
  # when displaying the topic we pull the xml doc out
  # and make the tag's values available as variables to the template
  belongs_to :topic_type

  # each topic or content item lives in exactly one basket
  belongs_to :basket

  # where we handle creator and contributor tracking
  include HasContributors

  # all our ZOOM_CLASSES need this to be searchable by zebra
  include ConfigureActsAsZoomForKete

  # other points:
  # should be versioned see acts_as_versioned
  # we probably want acts_as_commentable or role our own - the question being how one can see comments by commenter
  # see http://blog.caboo.se/articles/2006/02/21/eager-loading-with-cascaded-associations
  # about cascading eager associations, note that patch mentioned is now in edge

  # this is where we handled "related to"
  has_many :content_item_relations,
  :order => 'position', :dependent => :destroy
  # by using has_many :through associations we gain some bidirectional flexibility
  # with our polymorphic join model
  # basicaly specifically name the classes on the other side of the relationship here
  # see http://blog.hasmanythrough.com/articles/2006/04/03/polymorphic-through
  ZOOM_CLASSES.each do |zoom_class|
    if zoom_class == 'Topic'
      # special case
      # topics related to a topic
      has_many :child_related_topics, :through => :content_item_relations,
      :source => :child_related_topic,
      :conditions => "content_item_relations.related_item_type = 'Topic'",
      :include => :basket,
      :order => 'position'
    else
      has_many zoom_class.tableize.to_sym, :through => :content_item_relations,
      :source => zoom_class.tableize.singularize.to_sym,
      :conditions => ["content_item_relations.related_item_type = ?", zoom_class],
      :include => :basket,
      :order => 'position'
    end
  end

  acts_as_taggable
  acts_as_versioned
  validates_xml :extended_content
  validates_presence_of :title
  # this may change
  validates_uniqueness_of :title
  # TODO: add validation that prevents markup in short_summary
  # globalize stuff, uncomment later
  # translates :title, :description, :short_summary, :extended_content

  # methods related to handling the xml kept in extended_content column
  include ExtendedContent

  def related_topics
    # parents unfortunately get confused and return the content_item_relatations.id as id
    # spell it out in select
    # a tad brittle
    parent_topics = self.class.find(:all,
                                    :select => "topics.*, content_item_relations.position,
                                                content_item_relations.topic_id,
                                                content_item_relations.related_item_id,
                                                content_item_relations.related_item_type",
                                    :joins => "INNER JOIN content_item_relations ON topics.id = content_item_relations.topic_id",
                                    :conditions => ["((content_item_relations.related_item_id = :object_id) AND (content_item_relations.related_item_type = :class_name))", { :object_id => self.id, :class_name => self.class.to_s}])
    parent_topics.each do |topic|
      logger.debug("what is id: "+ topic.id.to_s)
    end

    return parent_topics + self.child_related_topics - [self]
  end

  # make ids look like this for urls
    # /7-my-title-for-topic-7/
  # i.e. /id-title/
  # rails strips the non integers after the id
  def to_param
    require 'unicode'
    "#{id}"+Unicode::normalize_KD("-"+title+"-").downcase.gsub(/[^a-z0-9\s_-]+/,'').gsub(/[\s_-]+/,'-')[0..-2]
  end
end
