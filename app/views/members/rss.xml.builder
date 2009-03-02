@title = t('members.rss.title', :site_name => SITE_NAME, :basket_name => @current_basket.name)
xml.instruct! :xml, :version=>"1.0"
xml.rss(:version=>"2.0"){
  xml.channel{
    xml.title(@title)
    xml.link(request.protocol + request.host + request.request_uri)
    xml.description(t('members.rss.description', :basket_name => @current_basket.name))
    xml.language('en-nz')
    for member in @members
      xml.item do
        xml.title(member.user_name)
        # no description at this time
        # xml.description(member.flag)
        # rfc822
        xml.pubDate(member.created_at)
        xml.link(url_for_contributions_of(member, 'Topic'))
        xml.guid(url_for_profile_of(member))
      end
    end
  }
}
