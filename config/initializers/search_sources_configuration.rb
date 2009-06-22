if IS_CONFIGURED
  ExternalSearchSources[:authorized_role] = "site_admin"
  ExternalSearchSources[:unauthorized_path] = "/#{Basket.site_basket.urlified_name}"
  ExternalSearchSources[:default_url_options] = { :urlified_name => Basket.site_basket.urlified_name }
  ExternalSearchSources[:default_link_classes] = 'generic-result-wrapper skip_div_click'
  ExternalSearchSources[:image_link_classes] = 'image-result-wrapper skip_div_click'
  ExternalSearchSources[:cache_results] = true
end
