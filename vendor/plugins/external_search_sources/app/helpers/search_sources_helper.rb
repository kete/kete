module SearchSourcesHelper

  # This is the only method that should be used. The rest are internally used methods

  def display_search_sources(search_text, options = {})
    @do_not_cache = options[:do_not_cache] || false
    html = String.new

    conditions = Hash.new
    if options[:target]
      # support for :target and [:target1, :target2]
      targets = options[:target].is_a?(Array) ? options[:target] : [options[:target]]
      conditions[:conditions] = ["source_target IN (?)", targets.collect { |t| t.to_s }]
    end

    search_sources = SearchSource.all(conditions)
    search_sources.each do |source|
      html += @template.render('search_sources/search_source',
                               :search_text => search_text,
                               :source => source,
                               :options => options)
    end
    return html if html.blank?
    "<div id='search_sources'>" +
      "<h3 id='search_sources_heading'>" +
        (options[:title] || t('search_sources_helper.display_search_sources.other_resources')) +
      "</h3>" +
      html +
    "</div>"
  end

  # You shouldn't need to use the following methods. Though they are public (and need to be public)
  # they should only be called by the engine (things like output methods and active scaffold overides)

  def cache_result(*args, &block)
    !@do_not_cache && ExternalSearchSources[:cache_results] ? cache(args, &block) : yield
  end

  def cache_key_for(source)
    { :search_source => source.title_id, :id => params[:id].to_i }
  end

  def search_source_title_for(entry, length=50)
    entry.title ? truncate(strip_tags(entry.title).squish, :length => length, :omission => '...') : ''
  end

  def search_source_summary_for(entry, length=300)
    summary = entry.title
    summary += " - " + truncate(strip_tags(entry.summary).squish, :length => length, :omission => '...') if entry.summary
    summary
  end

  def search_source_image_for(entry)
    media_data = entry.media_thumbnail || entry.enclosure
    image_tag(media_data, :alt => "#{h(entry.title)}. ", :title => "#{h(entry.title)}. ", :width => 50, :height => 50)
  end

  [:or_syntax, :and_syntax, :not_syntax].each do |syntax|

    define_method "#{syntax.to_s}_form_column" do |record, input_name|
      value = if params[:record] && params[:record][syntax]
        params[:record][syntax]
      elsif !record.new_record?
        record.send(syntax)
      else
        nil
      end

      value = Hash.new if value.blank?
      html = String.new

      html += "<span id='record_#{syntax}_case_div'>" +
        label_tag("#{input_name}[case]", t("search_sources_helper.#{syntax.to_s}_form_column.case"), :class => 'inline') +
        select_tag("#{input_name}[case]", options_for_select(SearchSource.case_values, value[:case])) +
      '</span>'

      if syntax == :or_syntax
        html += " <span id='record_or_syntax_position_div'>"
        html += label_tag("#{input_name}[position]", t('search_sources_helper.or_syntax_form_column.position'), :class => 'inline')
        html += select_tag("#{input_name}[position]", options_for_select(SearchSource.or_positions, value[:position]))
        html += '</span>'
      end

      html = content_tag('div', html, :id => "#{syntax.to_s}_form_div")

      if syntax != :or_syntax
        html += content_tag('div', t("search_sources_helper.#{syntax.to_s}_form_column.not_available"),
                            :id => "#{syntax.to_s}_not_available", :style => 'font-size: 80%; display:none;')
        html += javascript_tag("function hide_or_show_and_not_syntax() {
          if ($('record_or_syntax_position').value == 'none') {
            $('#{syntax.to_s}_not_available').hide();
            $('#{syntax.to_s}_form_div').show();
          } else {
            $('#{syntax.to_s}_form_div').hide();
            $('#{syntax.to_s}_not_available').show();
          }
        }
        hide_or_show_and_not_syntax();
        $('record_or_syntax_position').observe('change', function(event){
          hide_or_show_and_not_syntax();
        });
        ")
      end

      html
    end

  end

end
