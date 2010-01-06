module ConfigureAsKeteContentItem
  unless included_modules.include? ConfigureAsKeteContentItem
    def self.included(klass)
      # each topic or content item lives in exactly one basket
      klass.send :belongs_to, :basket

      # where we handle creator and contributor tracking
      klass.send :include, HasContributors

      # all our ZOOM_CLASSES need this to be searchable by zebra
      klass.send :include, ConfigureActsAsZoomForKete

      # methods related to handling the xml kept in extended_content column
      klass.send :include, ExtendedContent

      # everything except comments themselves is commentable
      # we also skip related stuff for comments
      unless klass.name == 'Comment'
        # relate to topics
        klass.send :include, RelatedContent

        klass.send :include, KeteCommentable
      end

      # though comments don't use the related content relations directly
      # these convenience methods actually work for comments, too
      # and are conceptually the same to end user
      klass.send :include, RelatedItems

      # sanitize our descriptions and extended_content for security
      # see validate_as_sanitized_html below, too
      # but allow site admin to override
      klass.send :attr_accessor, :do_not_sanitize
      klass.send :acts_as_sanitized, :fields => [:description]

      # this allows us to turn on/off email notification per item
      klass.send :attr_accessor, :skip_email_notification

      # note, since acts_as_taggable doesn't support versioning
      # out of the box
      # we also track each versions raw_tag_list input
      # so we can revert later if necessary

      # Tags are tracked on a per-privacy basis.
      klass.send :acts_as_taggable_on, :public_tags
      klass.send :acts_as_taggable_on, :private_tags

      # we override acts_as_versioned dependent => delete_all
      # because of the complexity our relationships of our models
      # delete_all won't do the right thing (at least not in migrations)
      klass.send :acts_as_versioned, :association_options => { :dependent => :destroy }

      # this is a little tricky
      # the acts_as_taggable declaration for the original
      # is different than how we use tags on the versioned model
      # where we use it for flagging moderator options, like 'flag as inappropriate'
      # where 'inappropriate' is actually a tag on that particular version

      # Moderation flags are tracked in a separate context.
      Module.class_eval("#{klass.name}::Version").class_eval <<-RUBY
        acts_as_taggable_on :flags
        alias_method :tags, :flags
        alias_method :tag_list, :flag_list
        alias_method :tag_list=, :flag_list=
        alias_method :tag_counts, :flag_counts
        def latest_version
          @latest_version ||= #{klass.name}.find_by_id(self.#{klass.name.tableize.singularize}_id)
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

      # methods and declarations related to moderation and flagging
      klass.send :include, Flagging

      klass.send :validates_presence_of, :title

      klass.send :validates_as_sanitized_html, [:description, :extended_content]

      # TODO: globalize stuff, uncomment later
      # translates :title, :description

      klass.send :after_save, :update_taggings_basket_id
    end

    def update_taggings_basket_id
      self.taggings.each do |tagging|
        tagging.update_attribute(:basket_id, self.basket_id)
      end
    end

    # Implement attribute accessors for acts_as_licensed
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
  end
end
