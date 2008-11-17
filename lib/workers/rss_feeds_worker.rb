class RssFeedsWorker < BackgrounDRb::MetaWorker
  set_worker_name :rss_feeds_worker
  def create(args = nil)
    if (FREQUENCY_OF_RSS_FEED_UPDATES.is_a?(Integer) or FREQUENCY_OF_RSS_FEED_UPDATES.is_a?(Float)) and FREQUENCY_OF_RSS_FEED_UPDATES > 0
      # FREQUENCY_OF_RSS_FEED_UPDATES is in hours (we allow decimals)
      # so multiply it by 60 * 60 to get our seconds arg value
      frequency_in_seconds = FREQUENCY_OF_RSS_FEED_UPDATES * 60 * 60

      frequency_in_seconds = frequency_in_seconds.to_i

      add_periodic_timer(frequency_in_seconds) { update_rss_feeds }
    end
  end

  # periodically call update_feeds on every Feed
  # based on a system setting
  # also called when homepage options are updated
  def update_rss_feeds
    Feed.each do |feed|
      feed.update_feed
    end
  end
end
