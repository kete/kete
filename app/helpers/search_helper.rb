module SearchHelper
  # check for context, construct urls accordingly

  # take current url, replace :controller_for_zoom_class
  # with passed with one for passed in zoom_class
  def link_to_zoom_class_results(zoom_class,results_count)
    if params[:action] == 'all'
      link_to("#{zoom_class_plural_humanize(zoom_class)} (#{results_count})",
              :overwrite_params => {:controller_name_for_zoom_class => zoom_class_controller(zoom_class), :page => nil},
              :trailing_slash => true)
    else
      link_to("#{zoom_class_plural_humanize(zoom_class)} (#{results_count})",
              :overwrite_params => {:controller_name_for_zoom_class => zoom_class_controller(zoom_class), :page => nil})
    end

  end

  def link_to_previous_page(phrase,previous_page)
    link_to(phrase, :overwrite_params => { :page => previous_page })
  end

  def link_to_next_page(phrase,next_page)
     link_to(phrase, :overwrite_params => { :page => next_page })
  end

  # look in parameters for what this is a refinement of
  def last_part_of_title_if_refinement_of
    if !@tag.nil?
      return " tagged as \"#{@tag.name}\""
    elsif !@contributor.nil?
      return " contributed by \"#{link_to_profile_for(@contributor)}\""
    elsif !@source_item.nil?
      return " related to \"#{@source_item.title}\""
    else
      return ''
    end
  end
  def pagination_links(options = { })
    current_page = options[:current_page]
    previous_page = options[:previous_page]
    next_page = options[:next_page]
    last_page = options[:last_page]
    placement = options[:placement] || 'top'
    number_per_page = options[:number_per_page]

    html_string = String.new

    if placement != 'bottom' or (number_per_page > 5 and last_page > 1)
        html_string += "
                        <div id=\"prev-next\">"

      if current_page > 1
        html_string += link_to_previous_page('&lt;&lt; previous',previous_page)
      else
        html_string += "&lt;&lt; previous"
      end
      html_string += "&nbsp;"
      if current_page < last_page
        html_string += link_to_next_page('next &gt;&gt;',next_page)
      else
        html_string += "next &gt;&gt;"
      end
      html_string += "
                       </div>"
    end
  end
end
