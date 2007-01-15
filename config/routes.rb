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
