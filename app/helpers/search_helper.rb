module SearchHelper
  # check for context, construct urls accordingly

  # take current url, replace :controller_for_zoom_class
  # with passed with one for passed in zoom_class
  # def link_to_zoom_class_results(zoom_class, results_count, location = nil, text = nil)
  #   location = location || params.merge(:controller_name_for_zoom_class => zoom_class_controller(zoom_class), :page => nil)
  #   location.merge!({ :trailing_slash => true }) if location.is_a?(Hash) && params[:action] == 'all'
  #   text ||= "#{zoom_class_plural_humanize(zoom_class)} (#{number_with_delimiter(results_count)})"
  #   link_to(text, location, :tabindex => '1')
  # end

  # look in parameters for what this is a refinement of
  # def last_part_of_title_if_refinement_of(add_links = true)
  #   end_of_title_parts = Array.new

  #   end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.about_a', :topic_type_name => @topic_type.name) if !@topic_type.nil?

  #   if @tag.present?
  #     tag_link = link_to(@tag.name, { :controller => 'tags', :action => 'show', :id => @tag }, tag_show_link_options(@tag))
  #     end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.tagged_as', :tag_name => tag_link)
  #   end

  #   if !@contributor.nil?
  #     contributor = add_links ? link_to_profile_for(@contributor, nil, contributor_show_link_options(@contributor)) : @contributor.user_name
  #     contributor_string = t('search_helper.last_part_of_title_if_refinement_of.contributed_by', :contributor => contributor)
  #     contributor_string += ' ' + avatar_for(@contributor) if SystemSetting.enable_user_portraits? || SystemSetting.enable_gravatar_support?
  #     end_of_title_parts << contributor_string
  #   end

  #   unless @limit_to_choice.nil?
  #     end_of_title_parts << "#{@extended_field ? t('search_helper.last_part_of_title_if_refinement_of.extended_field', :field_name => @extended_field.label.singularize.downcase) : ''}
  #                                                #{t('search_helper.last_part_of_title_if_refinement_of.limit_to_choice', :choice => @limit_to_choice.label)}"
  #   end

  #   unless @source_item.nil?
  #     @source_item.private_version! if permitted_to_view_private_items? && @source_item.latest_version_is_private?
  #     end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.related_to', :source_item => link_to_item(@source_item))
  #   end

  #   end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.date_since', :date => @date_since) unless @date_since.nil?
  #   end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.date_until', :date => @date_until) unless @date_until.nil?

  #   end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.privacy_type', :privacy => @privacy) if !@privacy.nil?

  #   end_of_title = end_of_title_parts.join(t('search_helper.last_part_of_title_if_refinement_of.and'))
  # end

  # We have to turn off linking to the contributor
  def last_part_of_title_for_rss_if_refinement_of
    last_part_of_title_if_refinement_of false
  end

  # def title_setup_first_part(title_so_far, span_around_zoom_class=false)
  #   if @current_basket != @site_basket
  #     title_so_far += @current_basket.name + ' '
  #   end
  #   zoom_class = zoom_class_from_controller(@controller_name_for_zoom_class)
  #   zoom_class_humanized = zoom_class_plural_humanize(zoom_class).downcase
  #   title_so_far += span_around_zoom_class \
  #                     ? content_tag('span', zoom_class_humanized, :class => 'current_zoom_class') \
  #                     : zoom_class_humanized
  # end

  # def search_results_info_and_links
  #   statement, links = Array.new, Array.new

  #   statement << t('search.results.showing_x-y_of_z',
  #                 :start => @start, :finish => @end_record,
  #                 :total => @result_sets[@current_class].size)

  #   links << '<div id="refine_search_dropdown_trigger"></div>'

  #   if @number_of_locations_count && @number_of_locations_count > 0
  #     statement << t('search.results.x-y_have_z_locations',
  #                    :start => @start, :finish => @end_record,
  #                    :n_locations => @number_of_locations_count)
  #     if params[:view_as] != 'map' && SystemSetting.enable_maps?
  #       links << link_to(t('search.results.view_map'), { :overwrite_params => { :view_as => 'map' } }, { :tabindex => '1' } )
  #     elsif params[:view_as] == 'map'
  #       links << link_to(t('search.results.view_list'), { :overwrite_params => { :view_as => nil } }, { :tabindex => '1' } )
  #     end
  #   end

  #   statement.join(', ') + " [ " + links.join(' | ') + " ] "
  # end

  # Used to check if an item is part of an existing relationship in related items search
  def related?(item)
    !@existing_ids.nil? && @existing_ids.member?(item.id)
  end

  def topic_related_thumbs_from(images, options = {})
    num_images_to_show = options[:num_images_to_show] ? options[:num_images_to_show] : SystemSetting.number_of_related_images_to_display
    num_images_to_show = [images.length, num_images_to_show].min

    output = '<ul class="images-list">'

    images[0, num_images_to_show].each do |image|
      output += '<li>'
      img_html_tag = image_tag image.thumbnail_file.public_filename, alt: altify(image.title)
      tabindex_attr = options[:tabindex] ? options[:tabindex] : 1

      output += if options[:link_to]
        link_to(img_html_tag, options[:link_to], tabindex: tabindex_attr)
      else
        img_html_tag
                end

      output += '</li>'
    end

    output += '<li>...</li>' if num_images_to_show < images.length
    output += '</ul>'
    output.html_safe
  end

  def will_paginate_atom(collection, xml)
    total_pages = WillPaginate::ViewHelpers.total_pages_for_collection(collection)
    xml.send('atom:link', rel: 'next', href: derive_url_for_rss(page: collection.current_page + 1)) unless collection.current_page.eql?(total_pages)
    xml.send('atom:link', rel: 'prev', href: derive_url_for_rss(page: collection.current_page - 1)) unless collection.current_page.eql?(1)
    xml.send('atom:link', rel: 'last', href: derive_url_for_rss(page: total_pages))
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

  def tag_show_link_options(tag)
    { title: t('search_helper.tag_show_link_options.title', tag_name: tag.name) }
  end

  def contributor_show_link_options(contributor)
    { title: t('search_helper.contributor_show_link_options.title', user_name: contributor.user_name) }
  end

  # Methods to replace the old and complex search routes. These should now pass
  # variables as query params.
  def basket_all_topic_type_path(*args)
    basket_search_all_path(*args)
  end
end
