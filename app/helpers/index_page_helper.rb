module IndexPageHelper
  def content_type_count_for(privacy, zoom_class)
    "#{number_with_delimiter(@items[privacy.to_sym]) || 0}"
  end

  def set_robots_txt_base_variables
    @actions = %w(new edit flag_version flag_form history preview selected_image)
    ZOOM_CLASSES.each do |stem|
      @actions << 'auto_complete_for_' + stem.tableize.singularize + '_tag_list'
    end

    @all_actions = %w(rss rss.xml contributed_by tagged related_to)

    @skip_controllers = %w(account baskets members extended_fields topic_types content_types zoom_dbs importers search)

    rule_bases = I18n.available_locales_with_labels.keys.collect { |key| '/' + key + '/' }
    rule_bases << '/'
    @rule_specs = rule_bases.collect { |base| 'Disallow: ' + base }
  end
end
