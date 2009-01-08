@title = SITE_NAME + ' - ' + @current_basket.name + ' - Moderate'
xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0"){
  xml.channel{
    xml.title(decode_and_escape(@title))
    xml.link(decode_and_escape(request.protocol + request.host + request.request_uri))
    xml.description("Items needing moderation")
    xml.language('en-nz')
    for item in @items
      xml.item do
        xml.title(decode_and_escape(item.title))
        xml.description(decode_and_escape(item.flag))
        # rfc822
        xml.pubDate(item.flagged_at)
        xml.link(decode_and_escape(history_url(item)))
        xml.guid(decode_and_escape(history_url(item)))
      end
    end
  }
}
