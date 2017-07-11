class SearchPresenter

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::UrlHelper

  private

  attr_reader :params, :query

  public

  def initialize(query: nil, results: [], params: {})
    if query
      @query = query
    else
      @query = SearchQuery.new(params)
    end

    @params = params
    @results_by_class = results
  end

  def paginated_results
    paginated_results_for(query.content_item_type) # => ActiveRecord::Relation
  end

  def results
    paginated_results_for(query.content_item_type).map do |model|
      SearchResultPresenter.new(model, query.searched_topic_id)
    end
  end

  def results_for(content_item_type)
    @results_by_class[content_item_type] # => ActiveRecord::Relation
  end

  def paginated_results_for(content_item_type)
    results_for(content_item_type).paginate(page: query.page) # => ActiveRecord::Relation
  end

  def count_for(content_item_type)
    if query.action == 'contributed_by'
      # distinct statments in Content's SQL break arel's count.
      @results_by_class[content_item_type].size # => Fixnum
    else
      @results_by_class[content_item_type].count # => Fixnum
    end
  end

  def link_path_params_for(content_item_type)
    {
      controller: @query.controller,
      action: @query.action,
      params: query_params_for(content_item_type)
    }
  end

  # TODO: should this be renamed url_safe_basket_name ??
  # EOIN: it's not clear whether this it he basket within which we are
  #       searching or the basket we are currently displaying
  def urlified_basket_name
    params[:urlified_name]
  end

  def date_since
    query.date_since # unless clear_values
  end

  def date_until
    query.date_until # unless clear_values
  end

  def extended_field
    params[:extended_field]
  end

  def limit_to_choice
    params[:limit_to_choice]
  end

  def view_as_choice_heirarchy?
    view_as == 'choice_hierarchy'
  end

  def view_as
    # map|choice_heirarchy
    params[:view_as]
  end

  def view_as_map?
    view_as == 'map'
  end

  def topic_type
    ''
  end

  def pagination_link_params
    query.pagination_link_params
  end

  def action
    # EOIN: this is heinous but Search.all_sort_types needs to be changed to fix it
    'for'
  end

  def category_columns
    browse_by_category_columns
  end

  def result_sets
    sets = {}
    content_item_types.map do |content_type|
      sets[content_type] = []
    end
    sets
  end

  def clear_values
    false
    # seems to be a flag that says whether the html form should have empty values
    # expects a boolean
  end

  def extended_field
    # expects a thing that implements #label
    OpenStruct.new(label: 'some label')
  end

  def title
    query.to_title
  end

  def current_basket
    Basket.site_basket # FIXME: make this find the basket the user is ucrrently in
  end

  def help_basket
    Basket.help_basket
  end

  def site_basket
    Basket.site_basket
  end

  def about_basket
    Basket.about_basket
  end

  def documentation_basket
    Basket.documentation_basket
  end

  def standard_baskets
    Basket.standard_basket_ids
  end

  def current_privacy
    default = current_basket.private_default_with_inheritance? ? 'private' : 'public'
    display_menu = true # EOIN: TODO: this method needs to be cleaned up
    ((params[:privacy_type] unless clear_values) || (SystemSetting.default_search_privacy if display_menu) || default)
  end

  def content_item_types
    # EOIN: these used to be called ZOOM_CLASSES
    # EOIN: TODO: not clear where we should pull this from yet
    %w(Topic StillImage AudioRecording Video WebLink Document)
  end

  def content_item_type_to_tab_nav_name(content_item_type)
    mapping = {   'Topic' => 'Topics',
        'StillImage' => 'Images',
        'AudioRecording' => 'Audio',
        'Video' => 'Video',
        'WebLink' => 'Web links',
        'Document' => 'Documents',
    }
    mapping[content_item_type] || 'Unknown content_item_type'
  end

  def search_sources_amount
    # FIXME: this model comes from a rails plugin in old kete
    # SearchSource.count(:conditions => ["source_target IN (?)", ['all', 'search']])
    0
  end

  def number_per_page
    10
  end

  def current_content_item_type
    query.content_item_type
  end

  def selected_content_item_type
    query.content_item_type
  end

  def sort_type_options_for(*args)
  end

  def basket_link
    basket_link = search_link_to_searched_basket
    t('search.for.whole_site') if basket_link.nil?
  end

  def search_terms_are_present?
    query.search_terms.present?
  end

  def search_terms
    query.search_terms
  end

  def link_to_add_item(options={})
    # phrase = options[:phrase]
    # item_class = options[:item_class]

    # phrase += ' ' + content_tag('span', zoom_class_humanize(item_class), :class => 'current_zoom_class')

    # if @current_basket != @site_basket
    #   phrase += t('application_helper.link_to_add_item.in_basket',
    #               :basket_name => @current_basket.name)
    # end

    # return link_to(phrase, {:controller => zoom_class_controller(item_class), :action => :new}, :tabindex => '1')
    ''
  end

  def topic_type_useful_here?(type)
    # display_search_field_for?(type, SystemSetting.display_topic_type_field) || params[:controller_name_for_zoom_class] == 'topics'
    true
  end

  def search_results_info_and_links
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
    ''
  end

  def query_params_for(content_item_type)
    query.query_params_for(content_item_type)
  end

  def link_text_for(content_item_type)
    count = count_for(content_item_type)
    text = content_item_type_to_tab_nav_name(content_item_type)
    "#{text} (#{number_with_delimiter(count)})"
  end

  private

  def search_link_to_searched_basket
    # html = String.new
    # html += ' ' + link_to_index_for(@current_basket, { :class => 'basket' }) if @current_basket != @site_basket
    ''
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
    'the title'
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
    ''
  end

end
