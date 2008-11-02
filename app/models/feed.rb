require 'open-uri'
require 'feed-normalizer'

class Feed < ActiveRecord::Base

  belongs_to :basket

  validates_presence_of :title
  validates_presence_of :url
  validates_uniqueness_of :url, :case_sensitive => false

  def latest_entries
    self.last_update = Time.now.utc.to_s :db
    self.save!

    entries = []
    feed = FeedNormalizer::FeedNormalizer.parse open(self.url)
    entries.push(*feed.entries)

    feed_limit = self.limit || 5
    entries[0..(feed_limit - 1)]
  end
end
