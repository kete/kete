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
        self.update_attributes({ :serialized_feed => entries,
                                 :last_downloaded => Time.now.utc.to_s(:db) })
        file_path = "#{Rails.root}/tmp/cache/views/feeds/#{self.basket.urlified_name}/feed_#{self.id}.cache"
        File.delete(file_path) if File.exists?(file_path)
      end
    rescue
      # fail silently - make sure nothing causes errors to output
    end
  end

  # for backgroundrb feeds_worker support
  def to_worker_key
    @feed_worker_key ||= id.to_s + "_feed_worker"
  end
end
