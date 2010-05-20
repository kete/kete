module SearchHelper
  # check for context, construct urls accordingly

  # take current url, replace :controller_for_zoom_class
  # with passed with one for passed in zoom_class
  def link_to_zoom_class_results(zoom_class, results_count, location = nil, text = nil)
    location = location || params.merge(:controller_name_for_zoom_class => zoom_class_controller(zoom_class), :page => nil)
    location.merge!({ :trailing_slash => true }) if location.is_a?(Hash) && params[:action] == 'all'
    text ||= "#{zoom_class_plural_humanize(zoom_class)} (#{number_with_delimiter(results_count)})"
    link_to(text, location, :tabindex => '1')
  end

  # look in parameters for what this is a refinement of
  def last_part_of_title_if_refinement_of(add_links = true)
    end_of_title_parts = Array.new

    end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.about_a', :topic_type_name => @topic_type.name) if !@topic_type.nil?

    end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.tagged_as', :tag_name => @tag.name) if !@tag.nil?

    if !@contributor.nil?
      contributor = add_links ? link_to_profile_for(@contributor) : @contributor.user_name
      contributor_string = t('search_helper.last_part_of_title_if_refinement_of.contributed_by', :contributor => contributor)
      contributor_string += ' ' + avatar_for(@contributor) if ENABLE_USER_PORTRAITS || ENABLE_GRAVATAR_SUPPORT
      end_of_title_parts << contributor_string
    end

    unless @limit_to_choice.nil?
      end_of_title_parts << "#{@extended_field ? t('search_helper.last_part_of_title_if_refinement_of.extended_field', :field_name => @extended_field.label.singularize.downcase) : ''}
                                                 #{t('search_helper.last_part_of_title_if_refinement_of.limit_to_choice', :choice => @limit_to_choice.label)}"
    end

    unless @source_item.nil?
      @source_item.private_version! if permitted_to_view_private_items? && @source_item.latest_version_is_private?
      end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.related_to', :source_item => link_to_item(@source_item))
    end

    end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.date_since', :date => @date_since) unless @date_since.nil?
    end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.date_until', :date => @date_until) unless @date_until.nil?

    end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.privacy_type', :privacy => @privacy) if !@privacy.nil?

    end_of_title = end_of_title_parts.join(t('search_helper.last_part_of_title_if_refinement_of.and'))
  end

  # We have to turn off linking to the contributor
  def last_part_of_title_for_rss_if_refinement_of
    last_part_of_title_if_refinement_of false
  end

  def title_setup_first_part(title_so_far, span_around_zoom_class=false)
    if @current_basket != @site_basket
      title_so_far += @current_basket.name + ' '
    end
    zoom_class = zoom_class_from_controller(@controller_name_for_zoom_class)
    zoom_class_humanized = zoom_class_plural_humanize(zoom_class).downcase
    title_so_far += span_around_zoom_class \
                      ? content_tag('span', zoom_class_humanized, :class => 'current_zoom_class') \
                      : zoom_class_humanized
  end

  def search_results_info_and_links
    statement, links = Array.new, Array.new

    statement << t('search.results.showing_x-y_of_z',
                  :start => @start, :finish => @end_record,
                  :total => @result_sets[@current_class].size)

    links << '<div id="refine_search_dropdown_trigger"></div>'

    if @number_of_locations_count && @number_of_locations_count > 0
      statement << t('search.results.x-y_have_z_locations',
                     :start => @start, :finish => @end_record,
                     :n_locations => @number_of_locations_count)
      if params[:view_as] != 'map'
        links << link_to(t('search.results.view_map'), { :overwrite_params => { :view_as => 'map' } }, { :tabindex => '1' } )
      elsif params[:view_as] == 'map'
        links << link_to(t('search.results.view_list'), { :overwrite_params => { :view_as => nil } }, { :tabindex => '1' } )
      end
    end

    statement.join(', ') + " [ " + links.join(' | ') + " ] "
  end

  # Used to check if an item is part of an existing relationship in related items search
  def related?(item)
    !@existing_ids.nil? && @existing_ids.member?(item.id)
  end

  def enable_start_unless_all_types_js_helper
    javascript_tag "
    function toggleDisabledStart(event) {
      var element = Event.element(event);

      if ( element.options[element.selectedIndex].value != \"all\" ) {
        $('start').disabled = false;
      } else {
        $('start').value = 'first';
        $('start').disabled = true;
      }
    }

    $('zoom_class').observe('change', toggleDisabledStart);"
  end

  def enable_end_unless_all_types_js_helper
    javascript_tag "
    function toggleDisabledStart(event) {
      var element = Event.element(event);

      if ( element.options[element.selectedIndex].value != \"all\" ) {
        $('end').disabled = false;
      } else {
        $('end').value = 'last';
        $('end').disabled = true;
      }
    }

    $('zoom_class').observe('change', toggleDisabledStart);"
  end

  def topic_related_thumbs_from(still_images_hash, options = { })
    image_tag_string = String.new
    image_tag_string += "<ul class=\"images-list\">" if options[:as_image_list]

    number_of_all_images = still_images_hash.size
    number_to_display = options[:number_to_display] ? options[:number_to_display] : NUMBER_OF_RELATED_IMAGES_TO_DISPLAY
    number_to_display = number_of_all_images > number_to_display ? number_to_display : number_of_all_images

    1.upto(number_to_display) do |key|
      key = key.to_s

      image_hash = still_images_hash[key][:thumbnail]
      image_hash[:alt] = altify(still_images_hash[key][:title])
      src = image_hash[:src]
      image_hash.delete(:size)
      image_hash.delete(:src)

      image_tag_string += "<li>" if options[:as_image_list]

      if options[:link_to]
        tabindex = options[:tabindex] ? options[:tabindex] : 1
        image_tag_string += link_to(image_tag(src, image_hash), options[:link_to], :tabindex => tabindex)
      else
        image_tag_string += image_tag(src, image_hash)
      end

      image_tag_string += "</li>" if options[:as_image_list]
    end

    # should we indicate there are more images
    unless number_to_display == number_of_all_images
      if options[:more]
        image_tag_string += "<li>" if options[:as_image_list]

        image_tag_string += options[:more]

        image_tag_string += "</li>" if options[:as_image_list]
      end
    end

    image_tag_string += "</ul>" if options[:as_image_list]
    image_tag_string
  end

  def will_paginate_atom(collection, xml)
    total_pages = WillPaginate::ViewHelpers.total_pages_for_collection(collection)
    xml.send("atom:link", :rel => 'next', :href => derive_url_for_rss(:page => collection.current_page + 1)) unless collection.current_page.eql?(total_pages)
    xml.send("atom:link", :rel => 'prev', :href => derive_url_for_rss(:page => collection.current_page - 1)) unless collection.current_page.eql?(1)
    xml.send("atom:link", :rel => 'last', :href => derive_url_for_rss(:page => total_pages))
  end

  def other_results
    other_results = Array.new
    (ZOOM_CLASSES - [@current_class]).each do |zoom_class|
      next unless @result_sets && @result_sets[zoom_class] && @result_sets[zoom_class].size > 0
      other_results << link_to_zoom_class_results(zoom_class, nil, nil, zoom_class_humanize_after(@result_sets[zoom_class].size, zoom_class))
    end
    other_results
  end

  # provides methods to determine which dc date values be displayed
  include SearchDcDateFormulator

end
