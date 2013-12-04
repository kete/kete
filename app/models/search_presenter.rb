class SearchPresenter

  def initialize(query: SearchQuery.new, results: [])
    @query = query
    @results = results
  end

  def results
    @results.map do |result|
      result.to_legacy_kete_format
    end
  end

  def title
    # title = title_setup_first_part(t('search.for.results_in'), true)
    # if @query.search_terms.present?
    #   title += t('search.for.current_search', search_terms: h(@query.search_terms))
    #   refinements = last_part_of_title_if_refinement_of
    #   title += t('search.for.refinements', :refinements => refinements) if !refinements.blank?
    # end
    "the title"
  end

  def current_basket
  end

  def sort_type_options_for(*args)
  end

  def basket_link
    basket_link = search_link_to_searched_basket
    t('search.for.whole_site') if basket_link.nil?
  end

  def search_terms_are_present?
    @query.search_terms.present?
  end

  def search_terms
    @query.search_terms
  end

  private

  def search_link_to_searched_basket
    # html = String.new
    # html += ' ' + link_to_index_for(@current_basket, { :class => 'basket' }) if @current_basket != @site_basket
    ""
  end


  def title_setup_first_part(title_so_far, span_around_zoom_class=false)
    # if @current_basket != @site_basket
    #   title_so_far += @current_basket.name + ' '
    # end
    # zoom_class = zoom_class_from_controller(@controller_name_for_zoom_class)
    # zoom_class_humanized = zoom_class_plural_humanize(zoom_class).downcase
    # title_so_far += span_around_zoom_class \
    #                   ? content_tag('span', zoom_class_humanized, :class => 'current_zoom_class') \
    #                   : zoom_class_humanized
    "the title"
  end

  def last_part_of_title_if_refinement_of(add_links = true)
    # end_of_title_parts = Array.new

    # end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.about_a', :topic_type_name => @topic_type.name) if !@topic_type.nil?

    # if @tag.present?
    #   tag_link = link_to(@tag.name, { :controller => 'tags', :action => 'show', :id => @tag }, tag_show_link_options(@tag))
    #   end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.tagged_as', :tag_name => tag_link)
    # end

    # if !@contributor.nil?
    #   contributor = add_links ? link_to_profile_for(@contributor, nil, contributor_show_link_options(@contributor)) : @contributor.user_name
    #   contributor_string = t('search_helper.last_part_of_title_if_refinement_of.contributed_by', :contributor => contributor)
    #   contributor_string += ' ' + avatar_for(@contributor) if SystemSetting.enable_user_portraits? || SystemSetting.enable_gravatar_support?
    #   end_of_title_parts << contributor_string
    # end

    # unless @limit_to_choice.nil?
    #   end_of_title_parts << "#{@extended_field ? t('search_helper.last_part_of_title_if_refinement_of.extended_field', :field_name => @extended_field.label.singularize.downcase) : ''}
    #                                              #{t('search_helper.last_part_of_title_if_refinement_of.limit_to_choice', :choice => @limit_to_choice.label)}"
    # end

    # unless @source_item.nil?
    #   @source_item.private_version! if permitted_to_view_private_items? && @source_item.latest_version_is_private?
    #   end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.related_to', :source_item => link_to_item(@source_item))
    # end

    # end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.date_since', :date => @date_since) unless @date_since.nil?
    # end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.date_until', :date => @date_until) unless @date_until.nil?

    # end_of_title_parts << t('search_helper.last_part_of_title_if_refinement_of.privacy_type', :privacy => @privacy) if !@privacy.nil?

    # end_of_title = end_of_title_parts.join(t('search_helper.last_part_of_title_if_refinement_of.and'))
    ""
  end

end
