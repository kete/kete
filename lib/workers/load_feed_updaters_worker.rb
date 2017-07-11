class LoadFeedUpdatersWorker < BackgrounDRb::MetaWorker
  set_worker_name :load_feed_updaters_worker

  # this worker is run once during backgroundrb startup to restart all Feed workers

  def create(args = nil)
    Feed.all.each do |feed|
      feed.update_feed
      MiddleMan.new_worker( worker: :feeds_worker, worker_key: feed.to_worker_key, data: feed.id )
    end

    exit # stop this worker
  end

end

