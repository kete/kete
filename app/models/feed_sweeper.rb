class FeedSweeper < ActionController::Caching::Sweeper
  observe Feed

  def after_save(feed)
    expire_fragment_for feed
  end

  def after_destroy(feed)
    expire_fragment_for feed
  end

  private

  def expire_fragment_for(feed)
    expire_fragment(:controller => 'index_page',
                    :action => 'index',
                    :urlified_name => feed.basket.urlified_name,
                    :part => "#{feed.title}_feed")
  end

end