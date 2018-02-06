# frozen_string_literal: true

require 'open-uri'
require 'feedzirra'

class Feed < ActiveRecord::Base
  belongs_to :basket

  before_validation :add_missing_values
  before_validation :convert_feed_to_http
  before_destroy :destroy_feed_workers
  before_destroy :destroy_caches

  validates_presence_of :title
  validates_presence_of :url
  validates_presence_of :update_frequency
  validates_presence_of :limit

  serialize :serialized_feed

  def self.fetch(url, escape = true)
    Rails.logger.debug("Original feed url: #{url}")
    url = escape ? URI.escape(url) : url
    Rails.logger.debug("Escaped feed url: #{url}")
    feed = Feedzirra::Feed.fetch_and_parse(url)
    # In the case that the feed can't be parsed, it returns a Fixnum, so check
    # if the output is a Feedzirra object, and if not, return a blank array
    feed.class.name =~ /Feedzirra/ ? feed.entries : []
  end

  def entries
    feed_limit = limit
    serialized_feed[0..(feed_limit - 1)]
  end

  def clear_caches
    I18n.available_locales_with_labels.keys.each do |locale|
      file_path = "#{Rails.root}/tmp/cache/views/feeds/#{locale}/#{basket.urlified_name}/feed_#{id}.cache"
      File.delete(file_path) if File.exist?(file_path)
    end
  end

  def destroy_caches
    clear_caches
  end

  def update_feed
    entries = Feed.fetch(url)
    if serialized_feed != entries # is there something different
      update_attributes({ 
                          serialized_feed: entries,
                          last_downloaded: Time.now.utc.to_s(:db) 
                        })
      clear_caches
    end
  rescue
    # fail silently - make sure nothing causes errors to output
  end

  # for backgroundrb feeds_worker support
  def to_worker_key
    @feed_worker_key ||= id.to_s + '_feed_worker'
  end

  private

  def add_missing_values
    self.update_frequency = update_frequency.present? ? update_frequency.to_i : 1
    self.limit = limit.present? ? limit.to_i : 5
  end

  def convert_feed_to_http
    self.url = url.strip.gsub('feed:', 'http:') if url.present?
  end

  include WorkerControllerHelpers # for deleting bgrb workers
  def destroy_feed_workers
    delete_existing_workers_for(:feeds_worker, to_worker_key, false)
  end
end
