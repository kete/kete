@title = SITE_NAME + ' - ' + @current_basket.name + ' - Moderate'
xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0"){
  xml.channel{
    xml.title(@title)
    xml.link(request.protocol + request.host + request.request_uri)
    xml.description("Items needing moderation")
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
