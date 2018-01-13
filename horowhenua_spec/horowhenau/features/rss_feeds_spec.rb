require 'spec_helper'


def update_timestamp(item)
  title = item.title

  item.update_attribute(:title, title + "CHANGE")
  item.update_attribute(:title, title)
end

def one_day_ago
  (DateTime.now - 1.day).iso8601
end

feature "RSS Feeds" do
  scenario "RSS links in footer are disabled" do
    visit "/"
    expect(page).to_not have_css("#linkToRSS")
  end

  scenario "RSS links in <head> are disabled" do
    visit "/"
    expect(page).to_not have_css("link[type='application/rss+xml']", visible: false)
  end

  it "for audio_recordings are available" do
    item = AudioRecording.find(1)
    update_timestamp(item)

    visit "/en/site/audio/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)

    stripped_xml = page.html.gsub(/^\s*/, '').gsub(/[\n\r]/, '')

    expect(page.html).to include    '<guid isPermaLink="false">rss:horowhenua.kete.net.nz:site:AudioRecording:1</guid>'
    expect(page.html).to include    '<title>Horowhenua song</title>'
    expect(page.html).to include    "<pubDate>#{item.updated_at.xmlschema}</pubDate>"
    expect(page.html).to include    '<link>http://www.example.com/en/site/audio/1-horowhenua-song</link>'

    expect(page.html).to include    '<dc:identifier>http://www.example.com/en/site/audio/1-horowhenua-song</dc:identifier>'
    expect(page.html).to include    '<dc:title>Horowhenua song</dc:title>'
    expect(page.html).to include    '<dc:publisher>horowhenua.kete.net.nz</dc:publisher>'
    expect(stripped_xml).to include '<dc:description><![CDATA[Presumably used at some promotion.We do not know who wrote or sang it.]]></dc:description>'
    expect(page.html).to include    '<dc:source>http://horowhenua.kete.net.nz/audio/1/Horowhenua_song.mp3</dc:source>'
    expect(page.html).to include    "<dc:date>#{item.updated_at.xmlschema}</dc:date>"
    expect(page.html).to include    '<dc:creator>Pippa</dc:creator>'
    expect(page.html).to include    '<dc:creator>pmc1</dc:creator>'
    expect(page.html).to include    '<dc:contributor>Rosalie</dc:contributor>'
    expect(page.html).to include    '<dc:contributor>rosalie</dc:contributor>'
    expect(page.html).to include    '<dc:type>Sound</dc:type>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[foxton]]></dc:subject>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[Ohau River]]></dc:subject>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[levin]]></dc:subject>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[Shannon]]></dc:subject>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[Hokio Beach]]></dc:subject>'
    expect(page.html).to include    '<dc:rights>http://creativecommons.org/licenses/by-nc-sa/3.0/nz/</dc:rights>'
    expect(page.html).to include    '<dc:format>audio/mpeg</dc:format>'
  end

  it "for documents are available" do
    item = Document.find(104)
    update_timestamp(item)

    visit "/en/site/documents/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)

    stripped_xml = page.html.gsub(/^\s*/, '').gsub(/[\n\r]/, '')

    expect(page.html).to include    '<guid isPermaLink="false">rss:horowhenua.kete.net.nz:site:Document:104</guid>'
    expect(page.html).to include    '<title>Minutes of Council Meeting 18 June 1906</title>'
    expect(page.html).to include    "<pubDate>#{item.updated_at.xmlschema}</pubDate>"
    expect(page.html).to include    '<link>http://www.example.com/en/site/documents/104-minutes-of-council-meeting-18-june-1906</link>'

    expect(page.html).to include    '<dc:identifier>http://www.example.com/en/site/documents/104-minutes-of-council-meeting-18-june-1906</dc:identifier>'
    expect(page.html).to include    '<dc:title>Minutes of Council Meeting 18 June 1906</dc:title>'
    expect(page.html).to include    '<dc:publisher>horowhenua.kete.net.nz</dc:publisher>'
    expect(stripped_xml).to include '<dc:description><![CDATA[Minutes of meeting of Council held in the Council Chambers on Monday 18th June 1906.]]></dc:description>'
    expect(stripped_xml).to include '<dc:description><![CDATA[PRESENT :&nbsp; The Mayor (Mr B R Gardener) and Councillors Hall, Hankins, Hudson, I&nbsp; Prouse, Levy and Ryder.  &nbsp;   The Minutes of the previous meeting were read and confirmed.   &nbsp;   Ranger   Concerning the appointment of Ranger it was decided to let the question of salary stand over until next meeting but on the motion of Cr Ryder seconded by Cr Hankins it was carried &ldquo;that Mr Cecil Wilson be appointed Ranger to this Council with power to impound all stock found wandering in the streets and roads of the Borough and that this appointment date him from the 18th June 1906 and be advertised.&rdquo;   &nbsp;   Amended Estimates   The Mayor moved and Cr J Prouse seconded &ldquo;That the estimates for the year ending 31st March 1907 as amended and now presented to the Council showing the income estimated at &pound;886 and the expenditure estimated at &pound;865 , be now finally approved by this Council&rdquo;.&nbsp; This was carried Crs Hankins, Hall &amp; Hudson voting against the motion.   &nbsp;   Mr Seddon&rsquo;s Death   The Mayor moved &amp; Councillor Hudson seconded the following resolution:-   &ldquo;That the Mayor &amp; Councillors on behalf of the citizens of Levin &ldquo;desire to express deepest and heartfelt sympathy with Mrs Seddon &ldquo;and family in their sudden and irreparable loss, and to place on &ldquo;record the high appreciation of the many valued services rendered &ldquo;to the Town and district of the late illustrious Premier&rdquo;   This was carried in silence. The members of the Council standing the while.   &nbsp;   Funeral Arrangements   It was then explained by the Mayor that as there was to be a Memorial Service in Levin on the day of the funeral of the late Rt. Hon. R J Seddon it seemed to him best to attend the local function, he would therefore be unable to represent the Council at the funeral - he consequently moved and Cr Prouse seconded and it was carried &ldquo;That this Council respectfully requests Mr W H Field, M.H.R., together with any Councillors present in Wellington to represent the Council &amp; Borough at the funeral of the late Premier, the Rt. Hon. R J Seddon.&rdquo;   &nbsp;   The Mayor moved, Cr Ryder seconded and it was carried &ldquo;That this Council do now adjourn until Monday next 25th inst.&rdquo;   &nbsp;   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; Confirmed&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;[signature]   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;June 25&nbsp; 1906  ]]></dc:description>'
    expect(page.html).to include    '<dc:source>http://horowhenua.kete.net.nz/documents/104/Meeting_6_compact_pdf.pdf</dc:source>'
    expect(page.html).to include    "<dc:date>#{item.updated_at.xmlschema}</dc:date>"
    expect(page.html).to include    '<dc:creator>Pippa</dc:creator>'
    expect(page.html).to include    '<dc:creator>pmc1</dc:creator>'
    expect(page.html).to include    '<dc:relation>http://www.example.com/en/site/topics/69-levin-borough-council-minutebook-1906-1908</dc:relation>'
    expect(page.html).to include    '<dc:type>InteractiveResource</dc:type>'
    expect(page.html).to include    '<dc:rights>http://creativecommons.org/licenses/by-nc-sa/3.0/nz/</dc:rights>'
    expect(page.html).to include    '<dc:format>application/pdf</dc:format>'
  end

  it "for still_images are available" do
    item = StillImage.find(251)
    update_timestamp(item)

    visit "/en/site/images/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)

    stripped_xml = page.html.gsub(/^\s*/, '').gsub(/[\n\r]/, '')

    expect(page.html).to include    '<guid isPermaLink="false">rss:horowhenua.kete.net.nz:site:StillImage:251</guid>'
    expect(page.html).to include    '<title>Foxton in the 1920\'s</title>'
    expect(page.html).to include    "<pubDate>#{item.updated_at.xmlschema}</pubDate>"
    expect(page.html).to include    '<link>http://www.example.com/en/site/images/251-foxton-in-the-1920s</link>'

    expect(page.html).to include    '<dc:identifier>http://www.example.com/en/site/images/251-foxton-in-the-1920s</dc:identifier>'
    expect(page.html).to include    '<dc:title>Foxton in the 1920\'s</dc:title>'
    expect(page.html).to include    '<dc:publisher>horowhenua.kete.net.nz</dc:publisher>'
    expect(stripped_xml).to include '<dc:description><![CDATA[This late 1920\'s scene changed little until 2002 when the New World Supermarket replaced the Moutoa Buildings (occupied at the time by J Walls) and Whyte\'s Hotel. On the opposite side of the street the Perreau Building\'s verandah stands out.At the far end of Main Street stands the water tower which was completed in 1923 and was a milestone in the town\'s history as the high pressure supply reduced the number of disastrous fires and enabled the town swimming pool to be built.Two other murals that were inside buildings are below.Artist: Des ComynSponsor: Property Brokers LtdSite: Clyde Street]]></dc:description>'
    expect(page.html).to include    '<dc:source>http://horowhenua.kete.net.nz/image_files/1231/foxtonm3.jpg</dc:source>'
    expect(page.html).to include    "<dc:date>#{item.updated_at.xmlschema}</dc:date>"
    expect(page.html).to include    '<dc:creator>Barb</dc:creator>'
    expect(page.html).to include    '<dc:creator>barbara</dc:creator>'
    expect(page.html).to include    '<dc:creator>Des Comyn</dc:creator>'
    expect(page.html).to include    '<dc:relation>http://www.example.com/en/site/topics/176-foxton-murals</dc:relation>'
    expect(page.html).to include    '<dc:type>StillImage</dc:type>'
    expect(page.html).to include    '<dc:rights>http://creativecommons.org/licenses/by-nc-sa/3.0/nz/</dc:rights>'
    expect(page.html).to include    '<dc:format>image/jpeg</dc:format>'
  end

  it "for topics are available" do
    item = Topic.find(171)
    update_timestamp(item)

    visit "/en/site/topics/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)

    stripped_xml = page.html.gsub(/^\s*/, '').gsub(/[\n\r]/, '')

    expect(page.html).to include    '<guid isPermaLink="false">rss:horowhenua.kete.net.nz:site:Topic:171</guid>'
    expect(page.html).to include    '<title>Horowhenua Animal Rescue Society</title>'
    expect(page.html).to include    "<pubDate>#{item.updated_at.xmlschema}</pubDate>"
    expect(page.html).to include    '<link>http://www.example.com/en/site/topics/171-horowhenua-animal-rescue-society</link>'

    expect(page.html).to include    '<dc:identifier>http://www.example.com/en/site/topics/171-horowhenua-animal-rescue-society</dc:identifier>'
    expect(page.html).to include    '<dc:title>Horowhenua Animal Rescue Society</dc:title>'
    expect(page.html).to include    '<dc:publisher>horowhenua.kete.net.nz</dc:publisher>'
    expect(stripped_xml).to include '<dc:description><![CDATA[Horowhenua Animal Rescue Society (Levin) is a voluntary group who provide a valuable service to the homeless animals of the Horowhenua. ]]></dc:description>'
    expect(stripped_xml).to include '<dc:description><![CDATA[Cindy Puketapu is the face of Horowhenua Animal Rescue.&nbsp;  Cindy has been involved in Animal rescue for around 20 years and moved the shelter on to her four-acre lifestyle block, in Ryder Crescent, 10 years ago after the death of Graeme Headley who had built it into a thriving organization.      The shelter cares for numerous dogs, cats and kittens until new homes can be found for them. Many find their new home as a result of the society&rsquo;s monthly newspaper advertising. Anyone wishing to adopt an animal can contact Cindy on 06-3688-569 or 027-2563-965.     Animal Rescue is run by a committee that works hard to provide funds to keep it going &ndash; committee contact is Ann (phone: 06 367 8552).]]></dc:description>'
    expect(page.html).to include    "<dc:date>#{item.updated_at.xmlschema}</dc:date>"
    expect(page.html).to include    '<dc:creator>Pippa</dc:creator>'
    expect(page.html).to include    '<dc:creator>pmc1</dc:creator>'
    expect(page.html).to include    '<dc:contributor>Joann Ransom</dc:contributor>'
    expect(page.html).to include    '<dc:contributor>ransomjo</dc:contributor>'
    expect(stripped_xml).to include '<dc:description><contact_phone_number>06-3688-569</contact_phone_number></dc:description>'
    expect(page.html).to include    '<dc:relation>http://www.example.com/en/site/topics/184-successful-animal-rehomes</dc:relation>'
    expect(page.html).to include    '<dc:relation>http://www.example.com/en/site/topics/103-ohau-we-love-to-dance-group</dc:relation>'
    expect(page.html).to include    '<dc:relation>http://www.example.com/en/site/documents/93-dr-doolittles-just-a-beginner-compared-to-our-cindy</dc:relation>'
    expect(page.html).to include    '<dc:type>InteractiveResource</dc:type>'
    expect(page.html).to include    '<dc:rights>http://creativecommons.org/licenses/by-nc-sa/3.0/nz/</dc:rights>'
    expect(page.html).to include    '<dc:format>text/html</dc:format>'
    expect(page.html).to include    '<dc:coverage>General</dc:coverage>'
    expect(page.html).to include    '<dc:coverage>Organisation</dc:coverage>'
  end

  it "for videos are available" do
    item = Video.find(3)
    update_timestamp(item)

    visit "/en/site/video/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)

    stripped_xml = page.html.gsub(/^\s*/, '').gsub(/[\n\r]/, '')

    expect(page.html).to include    '<guid isPermaLink="false">rss:horowhenua.kete.net.nz:site:Video:3</guid>'
    expect(page.html).to include    '<title>Summer Holiday</title>'
    expect(page.html).to include    "<pubDate>#{item.updated_at.xmlschema}</pubDate>"
    expect(page.html).to include    '<link>http://www.example.com/en/site/video/3-summer-holiday</link>'

    expect(page.html).to include    '<dc:identifier>http://www.example.com/en/site/video/3-summer-holiday</dc:identifier>'
    expect(page.html).to include    '<dc:title>Summer Holiday</dc:title>'
    expect(page.html).to include    '<dc:publisher>horowhenua.kete.net.nz</dc:publisher>'
    expect(stripped_xml).to include '<dc:description><![CDATA[The Ohau We Love to Dance made this video to wish everyone a Happy Summer Holiday 2006/7.Although we train our dogs for dancing, they also know how to enjoy themselves at the beach.]]></dc:description>'
    expect(page.html).to include    '<dc:source>http://horowhenua.kete.net.nz/video/3/summer_holiday_divx_pal.avi</dc:source>'
    expect(page.html).to include    "<dc:date>#{item.updated_at.xmlschema}</dc:date>"
    expect(page.html).to include    '<dc:creator>Pippa</dc:creator>'
    expect(page.html).to include    '<dc:creator>pmc1</dc:creator>'
    expect(page.html).to include    '<dc:relation>http://www.example.com/en/site/topics/103-ohau-we-love-to-dance-group</dc:relation>'
    expect(page.html).to include    '<dc:type>MovingImage</dc:type>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[canine freestyle]]></dc:subject>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[heelwork]]></dc:subject>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[levin]]></dc:subject>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[pippa]]></dc:subject>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[coard]]></dc:subject>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[waikawa]]></dc:subject>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[paws\'n\'music]]></dc:subject>'
    expect(page.html).to include    '<dc:rights>http://creativecommons.org/licenses/by-nc-sa/3.0/nz/</dc:rights>'
    expect(page.html).to include    '<dc:format>video/x-msvideo</dc:format>'
  end

  it "for web_links are available" do
    item = WebLink.find(36)
    update_timestamp(item)

    visit "/en/site/web_links/list.rss?updated_since=#{one_day_ago}"
    expect(page).to have_selector('item', count: 1)

    stripped_xml = page.html.gsub(/^\s*/, '').gsub(/[\n\r]/, '')

    expect(page.html).to include    '<guid isPermaLink="false">rss:horowhenua.kete.net.nz:site:WebLink:36</guid>'
    expect(page.html).to include    '<title>Tokomaru Steam Museum</title>'
    expect(page.html).to include    "<pubDate>#{item.updated_at.xmlschema}</pubDate>"
    expect(page.html).to include    '<link>http://www.example.com/en/site/web_links/36-tokomaru-steam-museum</link>'

    expect(page.html).to include    '<dc:identifier>http://www.example.com/en/site/web_links/36-tokomaru-steam-museum</dc:identifier>'
    expect(page.html).to include    '<dc:title>Tokomaru Steam Museum</dc:title>'
    expect(page.html).to include    '<dc:publisher>horowhenua.kete.net.nz</dc:publisher>'
    expect(stripped_xml).to include '<dc:subject><![CDATA[http://www.tokomarusteam.com]]></dc:subject>'
    expect(page.html).to include    "<dc:date>#{item.updated_at.xmlschema}</dc:date>"
    expect(page.html).to include    '<dc:creator>Barb</dc:creator>'
    expect(page.html).to include    '<dc:creator>barbara</dc:creator>'
    expect(page.html).to include    '<dc:contributor>Barb</dc:contributor>'
    expect(page.html).to include    '<dc:contributor>barbara</dc:contributor>'
    expect(page.html).to include    '<dc:relation>http://www.example.com/en/site/topics/194-tokomaru-steam-museum</dc:relation>'
    expect(page.html).to include    '<dc:type>InteractiveResource</dc:type>'
    expect(page.html).to include    '<dc:rights>http://creativecommons.org/licenses/by-nc-sa/3.0/nz/</dc:rights>'
    expect(page.html).to include    '<dc:format>text/html</dc:format>'
  end
end
