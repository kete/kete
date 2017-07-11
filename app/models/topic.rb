class Topic < ActiveRecord::Base

  include PgSearch
  include PgSearchCustomisations
  multisearchable against: [
    :title,
    :short_summary,
    :description,
    :raw_tag_list,
    :extended_content_values
  ]

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

  scope :in_basket, lambda { |basket| { conditions: { basket_id: basket } } }

  # a topic may be the designated index page for it's basket
  belongs_to :index_for_basket, class_name: 'Basket', foreign_key: 'index_for_basket_id'

  # where we handle creator and contributor tracking
  include HasContributors

  # all our ZOOM_CLASSES need this to be searchable by zebra
  # include ConfigureActsAsZoomForKete

  # we can't use object.comments, because that is used by related content stuff
  # has_many :comments, :as => :commentable, :dependent => :destroy, :order => 'position'
  include KeteCommentable

  # this is where we handled "related to"
  has_many :content_item_relations, order: 'position', dependent: :delete_all

  # Content Item Relationships when the topic is on the related_item end
  # of the relationship, and another topic occupies topic_id.
  has_many :child_content_item_relations, class_name: 'ContentItemRelation', as: :related_item, dependent: :delete_all
  has_many :parent_related_topics, through: :child_content_item_relations, source: :topic

  def self.updated_since(date)
    # Topic.where( <Topic or its join tables is newer than date>  )

    taggings_sql =                         Tagging.uniq.select(:taggable_id).where(taggable_type: 'Topic').where('created_at > ?', date).to_sql
    contributions_sql =                    Contribution.uniq.select(:contributed_item_id).where(contributed_item_type: 'Topic').where('updated_at > ?', date).to_sql
    content_item_relations_sql_1 =         ContentItemRelation.uniq.select(:related_item_id).where(related_item_type: 'Topic').where('updated_at > ?', date).to_sql
    content_item_relations_sql_2 =         ContentItemRelation.uniq.select(:topic_id).where('updated_at > ?', date).to_sql
    deleted_content_item_relations_sql_1 = "SELECT DISTINCT related_item_id FROM deleted_content_item_relations WHERE related_item_type = 'Topic' AND updated_at > ?"
    deleted_content_item_relations_sql_2 = 'SELECT DISTINCT topic_id FROM deleted_content_item_relations WHERE updated_at > ?'

    and_query = Topic.where('topics.  updated_at > ?', date).
                      where("topics.id IN ( #{taggings_sql} )"). # Tagging doesn't have an updated_at column.
                      where("topics.id IN ( #{contributions_sql} )").
                      where("topics.id IN ( #{content_item_relations_sql_1} )").
                      where("topics.id IN ( #{content_item_relations_sql_2} )").
                      where("topics.id IN ( #{deleted_content_item_relations_sql_1} )", date).
                      where("topics.id IN ( #{deleted_content_item_relations_sql_2} )", date)

    or_query = and_query.where_values.join(' OR ')

    Topic.where(or_query).uniq    # avoid repeated results from repeating ids.
  end

  def self.pre_load_associations
    # Speed up request with pre-loading of associations.
    includes(:creators).includes(:license).includes(:topic_type).includes(:basket)
  end

  def child_topic_content_relations
    content_item_relations.where(related_item_type: 'Topic').order(:position)
  end

  def child_related_topics
    join_as_related_item = 'JOIN content_item_relations ON content_item_relations.related_item_id = topics.id'
    Topic.joins(join_as_related_item).merge(child_topic_content_relations).includes(:basket)
  end

  # ZOOM_CLASSES:

  # ROB: I'd rather do these assocations as has_many() but I can't get this assocation working:
  #   has_many :audio_recording_relations, -> { where(related_item_type: "AudioRecording").order(:position) }, class_name: 'content_item_relations'
  # It'll probably be fixed in a later Rails.

  def still_images
    still_image_content_relations = content_item_relations.where(related_item_type: 'StillImage').order(:position)
    StillImage.joins(:content_item_relations).merge(still_image_content_relations).includes(:basket)
  end

  def audio_recordings
    audio_recording_content_relations = content_item_relations.where(related_item_type: 'AudioRecording').order(:position)
    AudioRecording.joins(:content_item_relations).merge(audio_recording_content_relations).includes(:basket)
  end

  def videos
    video_content_relations = content_item_relations.where(related_item_type: 'Video').order(:position)
    Video.joins(:content_item_relations).merge(video_content_relations).includes(:basket)
  end

  def web_links
    web_link_content_relations = content_item_relations.where(related_item_type: 'WebLink').order(:position)
    WebLink.joins(:content_item_relations).merge(web_link_content_relations).includes(:basket)
  end

  def documents
    document_content_relations = content_item_relations.where(related_item_type: 'Document').order(:position)
    ::Document.joins(:content_item_relations).merge(document_content_relations).includes(:basket)
  end

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
  acts_as_versioned association_options: { dependent: :destroy }

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
      (title == SystemSetting.no_public_version_title) || (title == SystemSetting.blank_title)
    end
    include FriendlyUrls
    def to_param; format_for_friendly_urls(true); end
  RUBY

  validates_xml :fixed_extended_content
  validates_presence_of :title

  def fixed_extended_content
    add_xml_fix(extended_content)
  end

  # TODO: add validation that prevents markup in short_summary
  # globalize stuff, uncomment later
  # translates :title, :description, :short_summary, :extended_content

  # methods related to handling the xml kept in extended_content column
  include ExtendedContent

  # methods and declarations related to moderation and flagging
  include Flagging

  # convenience methods for a topics relations
  include RelatedItems

  # methods for merging values from versions together
  include Merge

  # Private Item mixin
  include ItemPrivacy::ActsAsVersionedOverload
  include ItemPrivacy::TaggingOverload
  non_versioned_columns << 'private_version_serialized'

  after_save :store_correct_versions_after_save

  # Kieran Pilkington - 2008/10/21
  # Named scopes used in the index page controller for recent topics
  scope :recent, lambda { where('1 = 1').order('created_at DESC').limit(5) }
  scope :public, lambda { where('title != ?', SystemSetting.no_public_version_title) }
  scope :exclude_baskets_and_id, lambda {|basket_ids, id| where('basket_id NOT IN (?) AND id != ?', basket_ids, id) }

  after_save :update_taggings_basket_id

  def update_taggings_basket_id
    taggings.each do |tagging|
      tagging.update_attribute(:basket_id, basket_id)
    end
  end

  # Walter McGinnis, 2011-02-15
  # oEmbed Functionality

  # EOIN: disable Oembed for the moment. Is there a use case for it?
  # include OembedProvidable
  # oembed_providable_as :link
  # include KeteCommonOembedSupport

  # perhaps in the future we will store thumbnails for links (i.e. webpage previews)
  # for topics, but not at the moment
  # return nil for these
  %w(url height width).each do |method_stub|
    define_method('thumbnail_' + method_stub) do
      nil
    end
  end

  def related_topics(only_non_pending = false)
    if only_non_pending
      parent_related_topics.find_all_public_non_pending +
        child_related_topics.find_all_public_non_pending
    else
      parent_related_topics + child_related_topics
    end
  end

  def still_images
    content_item_relations.where(related_item_type: 'StillImage').map(&:related_item)
  end

  def first_related_image
    still_images.first || {}
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

  def basket_or_default
    basket.present? ? basket : Basket.find_by_urlified_name(SystemSetting.default_basket)
  end
end
