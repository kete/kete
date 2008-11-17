class FeedsWorker < BackgrounDRb::MetaWorker
  set_worker_name :feeds_worker
  set_no_auto_load true

  def create(args = nil)
    feed = Feed.find(args[:feed_id])
    frequency_in_seconds = (feed.update_frequency * 60 * 60).to_i
    add_periodic_timer(frequency_in_seconds) { update(feed) }
  end

  # periodically call update_feed on this feed
  # based on a per feed settings
  # also called when homepage options are updated
  def update(feed)
    feed.update_feed
  end
end
