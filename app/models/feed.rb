require 'open-uri'
require 'feed-normalizer'

class Feed < ActiveRecord::Base

  belongs_to :basket

  validates_presence_of :title
  validates_presence_of :url
  validates_presence_of :basket_id
  validates_presence_of :update_frequency

  serialize :serialized_feed

  def entries
    feed_limit = self.limit || 5
    self.serialized_feed[0..(feed_limit - 1)]
  end

  def update_feed
    begin
      entries = []
      feed = FeedNormalizer::FeedNormalizer.parse open(self.url)
      entries.push(*feed.entries)

      if self.serialized_feed != entries # is there something different
        self.serialized_feed = entries
        self.last_downloaded = Time.now.utc.to_s :db
        self.save
      end
    rescue
      # fail silently - make sure nothing causes errors to output
    end
  end

end
