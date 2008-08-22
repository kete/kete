module SearchHelper
  # check for context, construct urls accordingly

  # take current url, replace :controller_for_zoom_class
  # with passed with one for passed in zoom_class
  def link_to_zoom_class_results(zoom_class,results_count)
    if params[:action] == 'all'
      link_to("#{zoom_class_plural_humanize(zoom_class)} (#{number_with_delimiter(results_count)})",
              :overwrite_params => {:controller_name_for_zoom_class => zoom_class_controller(zoom_class), :page => nil},
              :trailing_slash => true)
    else
      link_to("#{zoom_class_plural_humanize(zoom_class)} (#{number_with_delimiter(results_count)})",
              :overwrite_params => {:controller_name_for_zoom_class => zoom_class_controller(zoom_class), :page => nil})
    end

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
  def last_part_of_title_if_refinement_of
    end_of_title_parts = Array.new

    end_of_title_parts << " tagged as \"#{@tag.name}\"" if !@tag.nil?

    end_of_title_parts << " contributed by \"#{link_to_profile_for(@contributor)}\"" if !@contributor.nil?

    end_of_title_parts << " related to \"#{@source_item.title}\"" if !@source_item.nil?

    end_of_title_parts << " that are #{@privacy}" if !@privacy.nil?

    end_of_title = end_of_title_parts.join(" and")
  end

  # depreciated, now use will_paginate
  def pagination_links(options = { })
    html_string = "depreciated, we now use will_paginate plugin"
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

end
