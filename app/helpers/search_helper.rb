module SearchHelper
  # check for context, construct urls accordingly

  # take current url, replace :controller_for_zoom_class
  # with passed with one for passed in zoom_class
  def link_to_zoom_class_results(zoom_class, results_count, location = nil)
    location = location || params.merge(:controller_name_for_zoom_class => zoom_class_controller(zoom_class), :page => nil)
    location.merge!({ :trailing_slash => true }) if location.is_a?(Hash) && params[:action] == 'all'
    link_to("#{zoom_class_plural_humanize(zoom_class)} (#{number_with_delimiter(results_count)})", location, :tabindex => '1')
  end

  # TODO: depreciated, remove 1.2
  def link_to_previous_page(phrase,previous_page)
    link_to(phrase, :overwrite_params => { :page => previous_page })
  end

  # TODO: depreciated, remove 1.2
  def link_to_next_page(phrase,next_page)
     link_to(phrase, :overwrite_params => { :page => next_page })
  end

  # look in parameters for what this is a refinement of
  def last_part_of_title_if_refinement_of(add_links = true)
    end_of_title_parts = Array.new

    end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.tagged_as', :tag_name => @tag.name) if !@tag.nil?

    if !@contributor.nil?
      contributor = add_links ? link_to_profile_for(@contributor) : @contributor.user_name
      contributor_string = t('search_helper.last_part_of_title_if_refinement_of.contributed_by', :contributor => contributor)
      contributor_string += ' ' + avatar_for(@contributor) if ENABLE_USER_PORTRAITS || ENABLE_GRAVATAR_SUPPORT
      end_of_title_parts << contributor_string
    end

    unless params[:limit_to_choice].blank?
      end_of_title_parts << "#{@extended_field ? t('search_helper.last_part_of_title_if_refinement_of.extended_field', :field_name => @extended_field.label.singularize.downcase) : ''}
                                                 #{t('search_helper.last_part_of_title_if_refinement_of.limit_to_choice', :choice => h(params[:limit_to_choice]))}"
    end

    unless @source_item.nil?
      @source_item.private_version! if permitted_to_view_private_items? && @source_item.latest_version_is_private?
      end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.related_to', :source_item => @source_item.title)
    end

    end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.privacy_type', :privacy => @privacy) if !@privacy.nil?

    end_of_title = end_of_title_parts.join(t('search_helper.last_part_of_title_if_refinement_of.and'))
  end

  # We have to turn off linking to the contributor
  def last_part_of_title_for_rss_if_refinement_of
    last_part_of_title_if_refinement_of false
  end

  # depreciated, now use will_paginate
  def pagination_links(options = { })
    html_string = t('search_helper.pagination_links.depreciated')
  end

  def title_setup_first_part(title_so_far)
    if @current_basket != @site_basket
      title_so_far += @current_basket.name + ' '
    end
    title_so_far += @controller_name_for_zoom_class.gsub(/_/, " ")
  end

  def toggle_in_reverse_field_js_helper
    javascript_tag "
    function toggleDisabledSortDirection(event) {
      var element = Event.element(event);

      $('sort_direction').checked = ( element.options[element.selectedIndex].value != \"none\" && $('sort_direction').checked );

      $('sort_direction').disabled = ( element.options[element.selectedIndex].value == \"none\" );

      if ( element.options[element.selectedIndex].value == \"none\" ) {
        $('sort_direction_field').hide()
      } else {
        $('sort_direction_field').show()
      }
    }

    $('sort_type').observe('change', toggleDisabledSortDirection);"
  end

  def instantiate_from_results(result_hash)
    raise "A hash must be passed in. Arrays are not acceptable." unless result_hash.instance_of?(Hash)

    eval("#{result_hash['class'].classify}").find(result_hash['id'])
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
    xml.tag!("atom:link".to_sym, :rel => 'next', :href => derive_url_for_rss(:page => collection.current_page + 1)) unless collection.current_page.eql?(total_pages)
    xml.tag!("atom:link".to_sym, :rel => 'prev', :href => derive_url_for_rss(:page => collection.current_page - 1)) unless collection.current_page.eql?(1)
    xml.tag!("atom:link".to_sym, :rel => 'last', :href => derive_url_for_rss(:page => total_pages))
  end

end


