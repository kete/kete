@title = SITE_NAME + ' - ' + @current_basket.name + ' - Latest 50 Members'
xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0"){
  xml.channel{
    xml.title(decode_and_escape(@title))
    xml.link(decode_and_escape(request.protocol + request.host + request.request_uri))
    xml.description(decode_and_escape("Members of #{@current_basket.name}"))
    xml.language('en-nz')
    for member in @members
      xml.item do
        xml.title(decode_and_escape(member.user_name))
        # no description at this time
        # xml.description(member.flag)
        # rfc822
        xml.pubDate(member.created_at)
        xml.link(decode_and_escape(url_for_contributions_of(member, 'Topic')))
        xml.guid(decode_and_escape(url_for_profile_of(member)))
      end
    end
  }
}
