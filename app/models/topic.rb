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
  # , :counter_cache => true
  belongs_to :basket

  # a topic may be the designated index page for it's basket
  belongs_to :index_for_basket, :class_name => 'Basket', :foreign_key => 'index_for_basket_id'

  # where we handle creator and contributor tracking
  include HasContributors

  # all our ZOOM_CLASSES need this to be searchable by zebra
  include ConfigureActsAsZoomForKete

  # we can't use object.comments, because that is used by related content stuff
  # has_many :comments, :as => :commentable, :dependent => :destroy, :order => 'position'
  include KeteCommentable

  # this is where we handled "related to"
  has_many :content_item_relations,
  :order => 'position', :dependent => :delete_all

  # Content Item Relationships when the topic is on the related_item end
  # of the relationship, and another topic occupies topic_id.
  has_many :child_content_item_relations, :class_name => "ContentItemRelation", :as => :related_item, :dependent => :delete_all
  has_many :parent_related_topics, :through => :child_content_item_relations, :source => :topic

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
      unless zoom_class == 'Comment'
        has_many zoom_class.tableize.to_sym, :through => :content_item_relations,
        :source => zoom_class.tableize.singularize.to_sym,
        :conditions => ["content_item_relations.related_item_type = ?", zoom_class],
        :include => :basket,
        :order => 'position'
      end
    end
  end

  # this allows for turning off sanitizing before save
  # and validates_as_sanitized_html
  # such as the case that a sysadmin wants to include a form
  attr_accessor :do_not_sanitize
  # sanitize our descriptions for security
  acts_as_sanitized :fields => [:description]

  # this allows us to turn on/off email notification per item
  attr_accessor :skip_email_notification

  # note, since acts_as_taggable doesn't support versioning
  # out of the box
  # we also track each versions raw_tag_list input
  # so we can revert later if necessary

  # Tags are tracked on a per-privacy basis.
  acts_as_taggable_on :public_tags
  acts_as_taggable_on :private_tags

  # we override acts_as_versioned dependent => delete_all
  # because of the complexity our relationships of our models
  # delete_all won't do the right thing (at least not in migrations)
  acts_as_versioned :association_options => { :dependent => :destroy }

  # acts as licensed but this is not versionable (cant change a license once it is applied)
  acts_as_licensed

  # this is a little tricky
  # the acts_as_taggable declaration for the original
  # is different than how we use tags on the versioned model
  # where we use it for flagging moderator options, like 'flag as inappropriate'
  # where 'inappropriate' is actually a tag on that particular version

  # Moderation flags are tracked in a separate context.
  Topic::Version.class_eval <<-RUBY
    acts_as_taggable_on :flags
    alias_method :tags, :flags
    alias_method :tag_list, :flag_list
    alias_method :tag_list=, :flag_list=
    alias_method :tag_counts, :flag_counts
    def latest_version
      @latest_version ||= Topic.find_by_id(self.topic_id)
    end
    def basket
      latest_version.basket
    end
    def first_related_image
      latest_version.first_related_image
    end
    def disputed_or_not_available?
      (title == NO_PUBLIC_VERSION_TITLE) || (title == BLANK_TITLE)
    end
    include FriendlyUrls
    def to_param; format_for_friendly_urls(true); end
  RUBY

  validates_xml :extended_content
  validates_presence_of :title

  validates_as_sanitized_html :description, :extended_content

  # TODO: add validation that prevents markup in short_summary
  # globalize stuff, uncomment later
  # translates :title, :description, :short_summary, :extended_content

  # methods related to handling the xml kept in extended_content column
  include ExtendedContent

  # methods and declarations related to moderation and flagging
  include Flagging

  # convenience methods for a topics relations
  include RelatedItems

  # Private Item mixin
  include ItemPrivacy::ActsAsVersionedOverload
  include ItemPrivacy::TaggingOverload
  self.non_versioned_columns << "private_version_serialized"


  after_save :store_correct_versions_after_save

  # James - 2008-09-08
  # Ensure basket cache is cleared if this is a standard basket home-page topic
  after_save :clear_basket_homepage_cache

  # Kieran Pilkington - 2008/10/21
  # Named scopes used in the index page controller for recent topics
  named_scope :recent, lambda { |*args|
    args = (args.first || {})
    { :order => 'created_at desc', :limit => 5 }.merge(args)
  }
  named_scope :public, :conditions => ['title != ?', NO_PUBLIC_VERSION_TITLE]

  after_save :update_taggings_basket_id

  def update_taggings_basket_id
    self.taggings.each do |tagging|
      tagging.update_attribute(:basket_id, self.basket_id)
    end
  end

  def clear_basket_homepage_cache
    self.basket.send(:reset_basket_class_variables) if self.basket.index_topic == self
  end

  private :clear_basket_homepage_cache

  def related_topics(only_non_pending = false)
    if only_non_pending
      parent_related_topics.find_all_public_non_pending +
        child_related_topics.find_all_public_non_pending
    else
      parent_related_topics + child_related_topics
    end
  end

  def first_related_image
    still_images.find_non_pending(:first) || {}
  end

  def title_for_license
    title
  end

  def author_for_license
    creator.user_name
  end

  def author_url_for_license
    "/#{Basket.find(1).urlified_name}/account/show/#{creator.to_param}"
  end

  # turn pretty urls on or off here
  include FriendlyUrls
  alias :to_param :format_for_friendly_urls

  def to_i
    id
  end

  # All available extended field mappings for this topic instance, including those from ancestors
  # of our TopicType.
  def all_field_mappings
    topic_type.all_field_mappings
  rescue
    []
  end

end
