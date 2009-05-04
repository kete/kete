module SearchSourcesHelper

  def display_search_sources
    html = String.new
    search_sources.each do |source|
      search_terms = search_terms_with_or(source, @item.title).escape_for_url
      search_source_url = URI.escape(source.base_url) + search_terms
      search_source_more = source.more_link_base_url \
                            ? (URI.escape(source.more_link_base_url) + search_terms) \
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

  def search_terms_with_or(source, terms)
    or_syntax = source.or_syntax

    return terms if or_syntax.blank?

    or_string = or_syntax[:case] == 'upper' ? 'OR' : 'or'
    case or_syntax[:position]
    when 'before'
      "#{or_string} #{terms}"
    when 'after'
      "#{terms} #{or_string}"
    when 'between'
      terms.strip.gsub(/\s/, " #{or_string} ")
    else
      terms
    end
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

  def or_syntax_form_column(record, input_name)
    value = if params[:record] && params[:record][:or_syntax]
      params[:record][:or_syntax]
    elsif !record.new_record?
      record.or_syntax
    else
      Hash.new
    end
    label_tag("#{input_name}[position]",
              t('search_sources_helper.or_syntax_form_column.position'),
              :class => 'inline') +
    select_tag("#{input_name}[position]",
               options_for_select(SearchSource.or_positions, value[:position])) + " " +
    content_tag('span', label_tag("#{input_name}[case]",
                                  t('search_sources_helper.or_syntax_form_column.case'),
                                  :class => 'inline') +
                        select_tag("#{input_name}[case]",
                                   options_for_select(SearchSource.or_case, value[:case])),
                :id => 'record_or_syntax_case_div') +
    javascript_tag("#{"$('record_or_syntax_case_div').hide();" if value[:position] == 'none'}
      $('record_or_syntax_position').observe('change', function(event) {
      if($('record_or_syntax_position').value == 'none') {
        $('record_or_syntax_case_div').hide();
      } else {
        $('record_or_syntax_case_div').show();
      }
    });")
  end

end
