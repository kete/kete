ExternalSearchSources[:authorized_role] = 'site_admin'
ExternalSearchSources[:unauthorized_path] = "/#{SystemSetting.default_basket}"
ExternalSearchSources[:default_url_options] = { urlified_name: SystemSetting.default_basket }
ExternalSearchSources[:default_link_classes] = 'generic-result-wrapper skip_div_click'
ExternalSearchSources[:image_link_classes] = 'image-result-wrapper skip_div_click'
ExternalSearchSources[:cache_results] = true
ExternalSearchSources[:source_targets] = %w{all search items}
ExternalSearchSources[:timeout] = 10 # (default is 2, but this may not be long enough)

module SearchSourcesHelper
  def cache_key_for(source)
    # If we are on an item page, make sure we add the item title to the cache key
    # so that if the title changes, the cache is made invalid and gets recreated
    if @current_item
      { search_source: source.title_id, id: params[:id].to_i, title: @current_item.to_param }
    else
      { search_source: source.title_id, id: params[:id].to_i }
    end
  end
end
