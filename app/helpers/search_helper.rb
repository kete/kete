module SearchHelper
  # check for context, construct urls accordingly

  # take current url, replace :controller_for_zoom_class
  # with passed with one for passed in zoom_class
  def link_to_zoom_class_results(zoom_class,results_count)
    link_to("#{zoom_class_plural_humanize(zoom_class)} (#{results_count})",
            :overwrite_params => {:controller_name_for_zoom_class => zoom_class_controller(zoom_class) })

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
      return " contributed by \"#{@contributor.login}\""
    elsif !@source_item.nil?
      return " related to \"#{@source_item.title}\""
    else
      return ''
    end
  end
end
