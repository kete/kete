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

  # Walter McGinnis, 2007-01-08
  # adding route for basket.urlified_name param
  # may also need route without format?
  map.basket_with_format ':urlified_name/:controller/:action/:id.:format'
  map.basket ':urlified_name/:controller/:action/:id'
  map.basket_root ':urlified_name', :controller => "search"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  # map.connect ':controller/service.wsdl', :action => 'wsdl'

  # default format route
  # map.connect ':controller/:action/:id.:format'

  # Install the default route as the lowest priority.
  # map.connect ':controller/:action/:id'

  # will default to site basket (special case of basket)
  # route site to search with DEFAULT_SEARCH_CLASS
  # :all is true by default if there are no search_terms
  map.connect '', :controller => "search"
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

