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

      klass.send :acts_as_versioned

      klass.send :acts_as_taggable

      klass.send :validates_presence_of, :title

      # this probably should change, particularly in still_image case
      # klass.send :validates_uniqueness_of, :title

      # TODO: globalize stuff, uncomment later
      # translates :title, :description
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
end
