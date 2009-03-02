@title = t('moderate.rss.title', :site_name => SITE_NAME, :basket_name => @current_basket.name)
xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0"){
  xml.channel{
    xml.title(@title)
    xml.link(request.protocol + request.host + request.request_uri)
    xml.description(t('moderate.rss.description'))
    xml.language('en-nz')
    for item in @items
      xml.item do
        xml.title(item.title)
        xml.description(item.flag)
        # rfc822
        xml.pubDate(item.flagged_at)
        xml.link(history_url(item))
        xml.guid(history_url(item))
      end
    end
  }
}
