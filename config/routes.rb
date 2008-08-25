ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up ''
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  map.oai '/oai_pmh_repository', :controller => 'oai_pmh_repository', :action => 'index'

  # Walter McGinnis, 2007-01-08
  # TODO: DRY this up
  map.basket_with_format ':urlified_name/:controller/:action/:id.:format'
  map.basket ':urlified_name/:controller/:action/:id'

  # Walter McGinnis, 2007-12-12
  # adding support for moderator feed
  map.basket_moderate_rss ':urlified_name/moderate/rss.:format', :controller => "moderate", :action => 'rss'

  # Walter McGinnis, 2008-05-25
  # adding support for basket members feed
  map.basket_moderate_rss ':urlified_name/members/rss.:format', :controller => "members", :action => 'rss'

  map.basket_index ':urlified_name', :controller => "index_page", :action => 'index'

  map.basket_all_rss ':urlified_name/all/:controller_name_for_zoom_class/rss.xml', :controller => "search", :action => 'rss'
  map.basket_all_private_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/rss.xml', :controller => "search", :action => 'rss'

  map.basket_all ':urlified_name/all/:controller_name_for_zoom_class/', :controller => "search", :action => 'all'
  map.basket_all_private ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/', :controller => "search", :action => 'all'

  map.basket_all_contributed_by_rss ':urlified_name/all/:controller_name_for_zoom_class/contributed_by/user/:contributor/rss.xml', :controller => "search", :action => 'rss'
  map.basket_all_private_contributed_by_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/rss.xml', :controller => "search", :action => 'rss'

  map.basket_all_contributed_by ':urlified_name/all/:controller_name_for_zoom_class/contributed_by/user/:contributor/', :controller => "search", :action => 'all'
  map.basket_all_private_contributed_by ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/', :controller => "search", :action => 'all'

  map.basket_all_related_to_rss ':urlified_name/all/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/rss.xml', :controller => "search", :action => 'rss'

  map.basket_all_related_to ':urlified_name/all/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/', :controller => "search", :action => 'all'

  map.basket_all_tagged_rss ':urlified_name/all/:controller_name_for_zoom_class/tagged/:tag/rss.xml', :controller => "search", :action => 'rss'
  map.basket_all_private_tagged_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/rss.xml', :controller => "search", :action => 'rss'

  map.basket_all_tagged ':urlified_name/all/:controller_name_for_zoom_class/tagged/:tag/', :controller => "search", :action => 'all'
  map.basket_all_private_tagged ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/', :controller => "search", :action => 'all'

  map.basket_search_contributed_by_rss ':urlified_name/search/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug/rss.xml', :controller => "search", :action => 'rss'
  map.basket_search_private_contributed_by_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug/rss.xml', :controller => "search", :action => 'rss'

  map.basket_search_contributed_by ':urlified_name/search/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug', :controller => "search", :action => 'for'
  map.basket_search_private_contributed_by ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug', :controller => "search", :action => 'for'

  map.basket_search_contributed_by_empty ':urlified_name/search/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug', :controller => "search", :action => 'for', :search_terms => nil
  map.basket_search_private_contributed_by_empty ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug', :controller => "search", :action => 'for', :search_terms => nil

  map.basket_search_related_to_rss ':urlified_name/search/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for/:search_terms_slug/rss.xml', :controller => "search", :action => 'rss'

  map.basket_search_related_to ':urlified_name/search/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for/:search_terms_slug', :controller => "search", :action => 'for'

  map.basket_search_related_to_empty ':urlified_name/search/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for', :controller => "search", :action => 'for', :search_terms => nil

  map.basket_search_tagged_rss ':urlified_name/search/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug/rss.xml', :controller => "search", :action => 'rss'
  map.basket_search_private_tagged_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug/rss.xml', :controller => "search", :action => 'rss'

  map.basket_search_tagged ':urlified_name/search/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug', :controller => "search", :action => 'for'
  map.basket_search_private_tagged ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug', :controller => "search", :action => 'for'

  map.basket_search_tagged_empty ':urlified_name/search/:controller_name_for_zoom_class/tagged/:tag/for', :controller => "search", :action => 'for', :search_terms => nil
  map.basket_search_private_tagged_empty ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/for', :controller => "search", :action => 'for', :search_terms => nil

  map.basket_search_rss ':urlified_name/search/:controller_name_for_zoom_class/for/:search_terms_slug/rss.xml', :controller => "search", :action => 'rss'
  map.basket_search_private_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/for/:search_terms_slug/rss.xml', :controller => "search", :action => 'rss'

  map.basket_search ':urlified_name/search/:controller_name_for_zoom_class/for/:search_terms_slug', :controller => "search", :action => 'for'
  map.basket_search_private ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/for/:search_terms_slug', :controller => "search", :action => 'for'

  map.basket_search_empty ':urlified_name/search/:controller_name_for_zoom_class/for', :controller => "search", :action => 'for', :search_terms => nil
  map.basket_search_private_empty ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/for', :controller => "search", :action => 'for', :search_terms => nil

  # James Stradling <james@katipo.co.nz>, 2008-04-15
  # Map private files to the PrivateFilesController
  # E.g. /documents/0000/0000/0011/Bio.txt
  map.private_file '/:type/:a/:b/:c/:filename.*formats', :controller => "private_files", :action => 'show'

  # will default to site basket (special case of basket)
  # route site to search with DEFAULT_SEARCH_CLASS
  # :all is true by default if there are no search_terms
  map.connect '/search', :controller => "search"

  # Walter McGinnis, 2007-07-13
  # if the site isn't configured, we don't setup our full routes
  if Object.const_defined?('SystemSetting') and ActiveRecord::Base.connection.table_exists?('system_settings') and SystemSetting.find(:all).size > 0
    is_configured = eval(SystemSetting.find_by_name('Is Configured').value)
  else
    is_configured = false
  end
  if is_configured
    # comment this line and uncomment the next after initial migration
    site_basket = Basket.find(1)
    site_urlified_name = !site_basket.nil? ? site_basket.urlified_name : 'site'
    map.connect '', :controller => "index_page", :urlified_name => site_urlified_name
  else
    # not configured, redirect to homepage which is configuration page
    map.connect '', :controller => "configure", :urlified_name => 'site'
  end

  # active_scaffold routes
  ACTIVE_SCAFFOLD_CONTROLLERS.each do |as_controller|
    map.resources as_controller.to_sym, :active_scaffold => true
  end

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  # map.connect ':controller/service.wsdl', :action => 'wsdl'

  # default format route
  # map.connect ':controller/:action/:id.:format'

  # Install the default route as the lowest priority.
  # map.connect ':controller/:action/:id'

  ### monitoring tools
  # to make sure the rails process is answering
  map.connect 'uptime.txt', :controller => "index_page", :action => 'uptime'
  # to make sure that the db is answering
  map.connect 'db_uptime.txt', :controller => "index_page", :action => 'db_uptime'
  # to make sure that the db is answering
  map.connect 'zebra_uptime.txt', :controller => "index_page", :action => 'zebra_uptime'
  # to make sure that registration is valid
  map.connect 'validate_kete_net_link.xml', :controller => "index_page", :action => 'validate_kete_net_link'

  map.connect '*path', :controller => 'application', :action => 'rescue_404' unless ActionController::Base.consider_all_requests_local
end

# route scratch

# example site/all/topics/
# basket/all/controller_name_for_zoom_class/ ->
# all items of that zoom_class in basket, with current tab reflecting
# if the user opts to search from this point, they go to basket/search/controller_name_for_zoom_class/for/search_term

# example walters_stuff/search/topics/
# basket/search/controller_name_for_zoom_class/ ->
# search from zoom_class as displayed tab
# SEE SEARCH RESULTS PATTERN AT END

# example walters_stuff/all/topics/contributed_by/user/7/
# basket/all/controller_name_for_zoom_class/contributed_by/user/id ->
# all contributions in a basket for a user with the zoom_class being the default tab

# example site/search/web_links/contributed_by/user/7/for/tramping
# basket/search/controller_name_for_zoom_class/contributed_by/user/id/for/search_term ->
# search within contributions in a basket for a user with zom_class being the current tab

# example walters_stuff/all/topics/related_to/image/6/
# basket/all/controller_name_for_zoom_class/related_to/controller_name_for_zoom_class_singular_for_related_to_item/id ->
# all related items in a basket for an item with the zoom_class being the default tab

# example site/search/web_links/related_to/image/6/for/ruby
# basket/search/controller_name_for_zoom_class/related_to/controller_name_for_zoom_class_singular_for_related_to_item/id/for/search_erm ->
# search related items in a basket for an item with the zoom_class being the default tab

# search results pattern:
# example site/search/topics/for/gertrude_stein
# basket/search/controller_name_for_zoom_class/for/search_term

# example site/search/topics/for/gertrude_stein_and_picasso
# basket/search/controller_name_for_zoom_class/for/search_term_1_boolean_operator_search_term_2

# may want to add a route something like this:
# basket/search/everything/for/search_term
# but limit it to rss only

# tech notes:
# need to create a "for" action in our search controller
# what is necessary for rss urls?

