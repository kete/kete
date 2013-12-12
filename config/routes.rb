  KeteApp::Application.routes.draw do

  ####################################################
  ####################################################
  # prepend locale to all routes 
  # * see routing-filter gem for details
  # * it prepends the :locale to all routes e.g. /de/ping

  # * it is not clear if this gem is still required in rails 3. We are
  #   keeping it around until we figure out whether the same stuff can be
  #   achieved with standard rails 3 routing stuff. EOIN: personally I am keen
  #   to do this to minimise our dependencies
  #   http://stackoverflow.com/questions/8459506/prepend-path-prefix-to-all-rails-routes
  #   http://stackoverflow.com/questions/4613996/implementing-account-scoping/4614466#4614466
  #   https://gist.github.com/pixeltrix/653543
  # scope(path: :locale) do
  #   # all other routes
  # end

  filter :locale


  ####################################################
  ####################################################



  match '/oai_pmh_repository' => 'oai_pmh_repository#index', :as => :oai

  # EOIN: rabid temp test route
  get '/ping' => 'ping#index'

  ####################################################
  ### monitoring tools ###############################

  # to make sure the rails process is answering
  match 'uptime.txt' => 'index_page#uptime'
  # to make sure that the db is answering
  match 'db_uptime.txt' => 'index_page#db_uptime'
  # to make sure that the zebra is answering
  match 'zebra_uptime.txt' => 'index_page#zebra_uptime'
  # to make sure that the backgroundrb is answering
  match 'bdrb_uptime.txt' => 'index_page#bdrb_uptime'
  # to make sure that registration is valid
  match 'validate_kete_net_link.xml' => 'index_page#validate_kete_net_link'
  # for search engines, ask them not to go to certain places
  match 'robots.txt' => 'index_page#robots'
  # for opensearch compatible clients
  match 'opensearchdescription.xml' => 'index_page#opensearchdescription'

  ####################################################
  ####################################################


  ####################################################
  # Various RSS feeds not associated with search #####
  
  match ':urlified_name/baskets/rss.:format' => 'baskets#rss', :as => :basket_list_rss
  match ':urlified_name/tags/rss.:format' => 'tags#rss', :as => :tags_list_rss
  match ':urlified_name/moderate/rss.:format' => 'moderate#rss', :as => :basket_moderate_rss
  match ':urlified_name/members/rss.:format' => 'members#rss', :as => :basket_moderate_rss

  ####################################################
  ####################################################


  ####################################################
  # terrible hacks ###################################

  match 'account/sign_up' => 'account#signup'
  match 'account/login' => 'account#login'
  match 'site/baskets/choose_type' => 'baskets#choose_type'
  match 'site/baskets/list' => 'baskets#list'
  match 'site/account/forgot_password' => 'account#forgot_password'

  match 'site/index_page/selected_image' => 'index_page#selected_image'
  match 'site/account/show_captcha' => 'account#show_captcha'
  match 'site/account/disclaimer/:id' => 'account#disclaimer'
  match 'topics/new' => 'topics#new'
  match 'tags/list' => 'tags#list'

  # TODO: In future these should be coalesced into the resources routing - we
  # are doing them individually because we don't want routes for actions that
  # do not exist (or behave in the standard RESTful way)

  get 'topics/:id'           => 'topics#show', as: 'topic'
  get 'audio_recordings/:id' => 'audio_recordings#show', as: 'audio_recording'
  get 'still_images/:id'     => 'still_images#show', as: 'still_image'
  get 'videos/:id'           => 'videos#show', as: 'video'
  get 'web_links/:id'        => 'web_links#show', as: 'web_link'
  get 'documents/:id'        => 'documents#show', as: 'document'
  get 'comments/:id'         => 'comments#show', as: 'comment'

  ####################################################
  ####################################################


  ####################################################
  # rails 3+ search routes ###########################

  match 'site/search/for' => 'search#for'
  match 'site/search/all' => 'search#all'
  match 'site/search/rss' => 'search#rss'

  # EOIN: I think we should change :urlified_name to :basket for all routes as it is clearer

  ####################################################
  ####################################################

  ####################################################
  # All search related routes (all, rss, for) ########
# 
#   match ':urlified_name/all/:controller_name_for_zoom_class/' => 'search#all', :as => :basket_all
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/' => 'search#all', :as => :basket_all_private
#   match ':urlified_name/all/:controller_name_for_zoom_class/of/:topic_type' => 'search#all', :as => :basket_all_topic_type
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/of/:topic_type' => 'search#all', :as => :basket_all_private_topic_type
#   match ':urlified_name/all/:controller_name_for_zoom_class/contributed_by/user/:contributor/' => 'search#all', :as => :basket_all_contributed_by
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/' => 'search#all', :as => :basket_all_private_contributed_by
#   match ':urlified_name/all/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice' => 'search#all', :as => :basket_all_of_category
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice' => 'search#all', :as => :basket_all_private_of_category
#   match ':urlified_name/all/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/' => 'search#all', :as => :basket_all_related_to
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/' => 'search#all', :as => :basket_all_private_related_to
#   match ':urlified_name/all/:contrller_name_for_zoom_class/tagged/:tag/' => 'search#all', :as => :basket_all_tagged
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/' => 'search#all', :as => :basket_all_private_tagged
#   match ':urlified_name/all/:controller_name_for_zoom_class/until/:date_until' => 'search#all', :as => :basket_all_date_until
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/until/:date_until' => 'search#all', :as => :basket_all_private_date_until
#   match ':urlified_name/all/:controller_name_for_zoom_class/since/:date_since' => 'search#all', :as => :basket_all_date_since
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/since/:date_since' => 'search#all', :as => :basket_all_private_date_since
#   match ':urlified_name/all/:controller_name_for_zoom_class/since/:date_since/until/:date_until' => 'search#all', :as => :basket_all_date_since_and_until
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/since/:date_since/until/:date_until' => 'search#all', :as => :basket_all_private_date_since_and_until
# 
#   match ':urlified_name/all/:controller_name_for_zoom_class/rss.xml' => 'search#rss', :as => :basket_all_rss
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/rss.xml' => 'search#rss', :as => :basket_all_private_rss
#   match ':urlified_name/all/:controller_name_for_zoom_class/of/:topic_type/rss.xml' => 'search#rss', :as => :basket_all_topic_type_rss
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/of/:topic_type/rss.xml' => 'search#rss', :as => :basket_all_private_topic_type_rss
#   match ':urlified_name/all/:controller_name_for_zoom_class/contributed_by/user/:contributor/rss.xml' => 'search#rss', :as => :basket_all_contributed_by_rss
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/rss.xml' => 'search#rss', :as => :basket_all_private_contributed_by_rss
#   match ':urlified_name/all/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/rss.xml' => 'search#rss', :as => :basket_all_related_to_rss
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/rss.xml' => 'search#rss', :as => :basket_all_private_related_to_rss
#   match ':urlified_name/all/:controller_name_for_zoom_class/tagged/:tag/rss.xml' => 'search#rss', :as => :basket_all_tagged_rss
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/rss.xml' => 'search#rss', :as => :basket_all_private_tagged_rss
#   match ':urlified_name/all/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/rss.xml' => 'search#rss', :as => :basket_all_of_category_rss
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/rss.xml' => 'search#rss', :as => :basket_all_private_of_category_rss
#   match ':urlified_name/all/:controller_name_for_zoom_class/until/:date_until/rss.xml' => 'search#rss', :as => :basket_all_date_until_rss
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/until/:date_until/rss.xml' => 'search#rss', :as => :basket_all_private_date_until_rss
#   match ':urlified_name/all/:controller_name_for_zoom_class/since/:date_since/rss.xml' => 'search#rss', :as => :basket_all_date_since_rss
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/since/:date_since/rss.xml' => 'search#rss', :as => :basket_all_private_date_since_rss
#   match ':urlified_name/all/:controller_name_for_zoom_class/since/:date_since/until/:date_until/rss.xml' => 'search#rss', :as => :basket_all_date_since_and_until_rss
#   match ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/since/:date_since/until/:date_until/rss.xml' => 'search#rss', :as => :basket_all_private_date_since_and_until_rss
#   match ':urlified_name/search/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_contributed_by_rss
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_private_contributed_by_rss
#   match ':urlified_name/search/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_related_to_rss
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_private_related_to_rss
#   match ':urlified_name/search/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_tagged_rss
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_private_tagged_rss
#   match ':urlified_name/search/:controller_name_for_zoom_class/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_rss
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_private_rss
#   match ':urlified_name/search/:controller_name_for_zoom_class/of/:topic_type/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_topic_type
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:topic_type/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_private_topic_type
#   match ':urlified_name/search/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_of_category_rss
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_private_of_category_rss
#   match ':urlified_name/search/:controller_name_for_zoom_class/until/:date_until/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_date_until_rss
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/until/:date_until/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_private_date_until_rss
#   match ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_date_since_rss
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_private_date_since_rss
#   match ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_date_since_and_until_rss
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for/:search_terms_slug/rss.xml' => 'search#rss', :as => :basket_search_private_date_since_and_until_rss
# 
#   match ':urlified_name/search/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug' => 'search#for', :as => :basket_search_contributed_by
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug' => 'search#for', :as => :basket_search_private_contributed_by
#   match ':urlified_name/search/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for/:search_terms_slug' => 'search#for', :as => :basket_search_related_to
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for/:search_terms_slug' => 'search#for', :as => :basket_search_private_related_to
#   match ':urlified_name/search/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug' => 'search#for', :as => :basket_search_tagged
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug' => 'search#for', :as => :basket_search_private_tagged
#   match ':urlified_name/search/:controller_name_for_zoom_class/for/:search_terms_slug' => 'search#for', :as => :basket_search
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/for/:search_terms_slug' => 'search#for', :as => :basket_search_private
#   match ':urlified_name/search/:controller_name_for_zoom_class/of/:topic_type/for/:search_terms_slug' => 'search#for', :as => :basket_search_topic_type
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:topic_type/for/:search_terms_slug' => 'search#for', :as => :basket_search_private_topic_type
#   match ':urlified_name/search/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for/:search_terms_slug' => 'search#for', :as => :basket_search_of_category
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for/:search_terms_slug' => 'search#for', :as => :basket_search_private_of_category
#   match ':urlified_name/search/:controller_name_for_zoom_class/until/:date_until/for/:search_terms_slug' => 'search#for', :as => :basket_search_date_until
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/until/:date_until/for/:search_terms_slug' => 'search#for', :as => :basket_search_private_date_until
#   match ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/for/:search_terms_slug' => 'search#for', :as => :basket_search_date_since
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/for/:search_terms_slug' => 'search#for', :as => :basket_search_private_date_since
#   match ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for/:search_terms_slug' => 'search#for', :as => :basket_search_date_since_and_until
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for/:search_terms_slug' => 'search#for', :as => :basket_search_private_date_since_and_until
# 
#   # There were duplicate routes (i.e. redundant) with a ":search_terms => nil" option,
#   match ':urlified_name/search/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug' => 'search#for', :as => :basket_search_contributed_by_empty, :search_terms => nil
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug' => 'search#for', :as => :basket_search_private_contributed_by_empty, :search_terms => nil
#   match ':urlified_name/search/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for' => 'search#for', :as => :basket_search_related_to_empty, :search_terms => nil
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for' => 'search#for', :as => :basket_search_private_related_to_empty, :search_terms => nil
#   match ':urlified_name/search/:controller_name_for_zoom_class/tagged/:tag/for' => 'search#for', :as => :basket_search_tagged_empty, :search_terms => nil
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/for' => 'search#for', :as => :basket_search_private_tagged_empty, :search_terms => nil
#   match ':urlified_name/search/:controller_name_for_zoom_class/for' => 'search#for', :as => :basket_search_empty, :search_terms => nil
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/for' => 'search#for', :as => :basket_search_private_empty, :search_terms => nil
#   match ':urlified_name/search/:controller_name_for_zoom_class/of/:topic_type/for' => 'search#for', :as => :basket_search_topic_type, :search_terms => nil
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:topic_type/for' => 'search#for', :as => :basket_search_private_topic_type, :search_terms => nil
#   match ':urlified_name/search/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for' => 'search#for', :as => :basket_search_of_category_empty, :search_terms => nil
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for' => 'search#for', :as => :basket_search_private_of_category_empty, :search_terms => nil
#   match ':urlified_name/search/:controller_name_for_zoom_class/until/:date_until/for' => 'search#for', :as => :basket_search_date_until, :search_terms => nil
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/until/:date_until/for' => 'search#for', :as => :basket_search_private_date_until, :search_terms => nil
#   match ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/for' => 'search#for', :as => :basket_search_date_since, :search_terms => nil
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/for' => 'search#for', :as => :basket_search_private_date_since, :search_terms => nil
#   match ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for' => 'search#for', :as => :basket_search_date_since_and_until, :search_terms => nil
#   match ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for' => 'search#for', :as => :basket_search_private_date_since_and_until, :search_terms => nil

  ####################################################
  ####################################################


  # active_scaffold routes
  ACTIVE_SCAFFOLD_CONTROLLERS.each do |as_controller|
    resources as_controller.to_sym, :active_scaffold => true, :path_prefix => ':urlified_name'
  end

  match ':urlified_name' => 'index_page#index', :as => :basket_index
  match ':urlified_name/contact' => 'baskets#contact', :as => :basket_contact

  # James Stradling <james@katipo.co.nz>, 2008-04-15
  # Map private files to the PrivateFilesController
  # E.g. /documents/0000/0000/0011/Bio.txt
  match '/:type/:a/:b/:c/:filename.*formats' => 'private_files#show', :as => :private_file

  # Catch everything else
  match ':urlified_name/:controller/:action/:id.:format' => '#index', :as => :basket_with_format
  match ':urlified_name/:controller/:action/:id' => '#index', :as => :basket


  # Walter McGinnis, 2007-07-13
  # if the site isn't configured, we don't setup our full routes
  # skip_configuration = Object.const_defined?(:SKIP_SYSTEM_CONFIGURATION)
  # is_configured = false

  # if !skip_configuration &&
  #       Object.const_defined?('SystemSetting') &&
  #       ActiveRecord::Base.connection.table_exists?('system_settings') &&
  #       SystemSetting.find(:all).size > 0
  #   is_configured = eval(SystemSetting.find_by_name('Is Configured').value)
  # end
  # if skip_configuration || is_configured
  #   # comment this line and uncomment the next after initial migration
  #   site_basket = Basket.find(1) unless skip_configuration # we skip a query here if running integration tests
  #   site_urlified_name = !site_basket.nil? ? site_basket.urlified_name : 'site'
  #   root :to => 'index_page#index', :urlified_name => site_urlified_name
  # else
  #   # not configured, redirect to homepage which is configuration page
  #   root :to => 'configure#index', :urlified_name => 'site'
  # end

  # EOIN: hard-code the site basket's urlified name to 'site'
  site_urlified_name = 'site'
  root :to => 'index_page#index', :urlified_name => site_urlified_name

  # EOIN: this route matches everything and sends the browser to the #rescue_404 action in ApplicationController 
  match '*path' => 'application#rescue_404' unless Rails.application.config.consider_all_requests_local
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

