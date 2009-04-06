module SearchSourcesHelper

  def display_search_sources
    html = String.new
    search_sources.each do |source|
      search_source_url = source.base_url + @item.title.escape_for_url
      search_source_more = source.more_link_base_url \
                            ? (source.more_link_base_url + @item.title.escape_for_url) \
                            : search_source_url
      html += @template.render('search_sources/search_source',
                               :source => source,
                               :search_source_id => source.title_id,
                               :search_source_url => search_source_url,
                               :search_source_more => search_source_more)
    end
    return html if html.blank?
    "<div id='search_sources'>" +
      "<h3>#{t('search_sources_helper.display_search_sources.other_resources')}</h3>" +
      html +
    "</div>"
  end

  def search_sources_sort(entries, limit)
    links = Array.new
    images = Array.new
    entries[0..(limit - 1)].each do |entry|
      if !entry.media_thumbnail.nil? || !entry.enclosure.nil?
        images << entry
      else
        links << entry
      end
    end
    { :links => links, :images => images }
  end

  def search_source_title_for(entry, length=300)
    entry.summary ? truncate(strip_tags(entry.summary).squish, :length => length, :omission => '...') : ''
  end

  def search_source_image_for(entry)
    image_path = !entry.media_thumbnail.nil? ? entry.media_thumbnail : entry.enclosure
    image_tag(image_path, :alt => "#{h(entry.title)}. ", :title => "#{h(entry.title)}. ", :width => 50, :height => 50)
  end

end
