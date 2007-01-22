module RelatedContent
  # this is where we handled "related to"
  # all our content items are related to topics
  # only topics can be related to another item of the same type
  # see app/model/topic.rb for the other side of the relationship
  unless included_modules.include? RelatedContent
    def self.included(klass)
      klass.send :has_many, :content_item_relations, :as => :related_item, :dependent => :delete_all
      klass.send :has_many, :topics, :through => :content_item_relations
    end
  end
end
