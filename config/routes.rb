ActionController::Routing::Routes.draw do |map|

  map.filter 'locale'

  Translate::Routes.translation_ui(map) if RAILS_ENV != "production"

  map.oai '/oai_pmh_repository', :controller => 'oai_pmh_repository', :action => 'index'

  ### monitoring tools
  map.with_options :controller => 'index_page' do |index_page|
    # to make sure the rails process is answering
    index_page.connect 'uptime.txt', :action => 'uptime'
    # to make sure that the db is answering
    index_page.connect 'db_uptime.txt', :action => 'db_uptime'
    # to make sure that the db is answering
    index_page.connect 'zebra_uptime.txt', :action => 'zebra_uptime'
    # to make sure that registration is valid
    index_page.connect 'validate_kete_net_link.xml', :action => 'validate_kete_net_link'
    # for search engines, ask them not to go to certain places
    index_page.connect 'robots.txt', :action => 'robots'
    # for opensearch compatible clients
    index_page.connect 'opensearchdescription.xml', :action => 'opensearchdescription'
  end

  # Various RSS feeds not associated with search
  map.with_options :action => "rss" do |rss|
    rss.basket_list_rss ':urlified_name/baskets/rss.:format', :controller => "baskets"
    rss.tags_list_rss ':urlified_name/tags/rss.:format', :controller => "tags"
    rss.basket_moderate_rss ':urlified_name/moderate/rss.:format', :controller => "moderate"
    rss.basket_moderate_rss ':urlified_name/members/rss.:format', :controller => "members"
  end

  # All search related routes (all, rss, for)
  map.with_options :controller => 'search' do |search|

    search.with_options :action => 'all' do |search_all|
      search_all.basket_all ':urlified_name/all/:controller_name_for_zoom_class/'
      search_all.basket_all_private ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/'
      search_all.basket_all_topic_type ':urlified_name/all/:controller_name_for_zoom_class/of/:topic_type'
      search_all.basket_all_private_topic_type ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/of/:topic_type'
      search_all.basket_all_contributed_by ':urlified_name/all/:controller_name_for_zoom_class/contributed_by/user/:contributor/'
      search_all.basket_all_private_contributed_by ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/'
      search_all.basket_all_of_category ':urlified_name/all/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice'
      search_all.basket_all_private_of_category ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice'
      search_all.basket_all_related_to ':urlified_name/all/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/'
      search_all.basket_all_private_related_to ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/'
      search_all.basket_all_tagged ':urlified_name/all/:controller_name_for_zoom_class/tagged/:tag/'
      search_all.basket_all_private_tagged ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/'
      search_all.basket_all_date_until ':urlified_name/all/:controller_name_for_zoom_class/until/:date_until'
      search_all.basket_all_private_date_until ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/until/:date_until'
      search_all.basket_all_date_since ':urlified_name/all/:controller_name_for_zoom_class/since/:date_since'
      search_all.basket_all_private_date_since ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/since/:date_since'
      search_all.basket_all_date_since_and_until ':urlified_name/all/:controller_name_for_zoom_class/since/:date_since/until/:date_until'
      search_all.basket_all_private_date_since_and_until ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/since/:date_since/until/:date_until'
    end

    search.with_options :action => 'rss' do |search_rss|
      search_rss.basket_all_rss ':urlified_name/all/:controller_name_for_zoom_class/rss.xml'
      search_rss.basket_all_private_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/rss.xml'
      search_rss.basket_all_topic_type_rss ':urlified_name/all/:controller_name_for_zoom_class/of/:topic_type/rss.xml'
      search_rss.basket_all_private_topic_type_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/of/:topic_type/rss.xml'
      search_rss.basket_all_contributed_by_rss ':urlified_name/all/:controller_name_for_zoom_class/contributed_by/user/:contributor/rss.xml'
      search_rss.basket_all_private_contributed_by_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/rss.xml'
      search_rss.basket_all_related_to_rss ':urlified_name/all/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/rss.xml'
      search_rss.basket_all_private_related_to_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/rss.xml'
      search_rss.basket_all_tagged_rss ':urlified_name/all/:controller_name_for_zoom_class/tagged/:tag/rss.xml'
      search_rss.basket_all_private_tagged_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/rss.xml'
      search_rss.basket_all_of_category_rss ':urlified_name/all/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/rss.xml'
      search_rss.basket_all_private_of_category_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/rss.xml'
      search_rss.basket_all_date_until_rss ':urlified_name/all/:controller_name_for_zoom_class/until/:date_until/rss.xml'
      search_rss.basket_all_private_date_until_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/until/:date_until/rss.xml'
      search_rss.basket_all_date_since_rss ':urlified_name/all/:controller_name_for_zoom_class/since/:date_since/rss.xml'
      search_rss.basket_all_private_date_since_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/since/:date_since/rss.xml'
      search_rss.basket_all_date_since_and_until_rss ':urlified_name/all/:controller_name_for_zoom_class/since/:date_since/until/:date_until/rss.xml'
      search_rss.basket_all_private_date_since_and_until_rss ':urlified_name/all/:privacy_type/:controller_name_for_zoom_class/since/:date_since/until/:date_until/rss.xml'
      search_rss.basket_search_contributed_by_rss ':urlified_name/search/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_private_contributed_by_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_related_to_rss ':urlified_name/search/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_private_related_to_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_tagged_rss ':urlified_name/search/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_private_tagged_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_rss ':urlified_name/search/:controller_name_for_zoom_class/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_private_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_topic_type ':urlified_name/search/:controller_name_for_zoom_class/of/:topic_type/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_private_topic_type ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:topic_type/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_of_category_rss ':urlified_name/search/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_private_of_category_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_date_until_rss ':urlified_name/search/:controller_name_for_zoom_class/until/:date_until/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_private_date_until_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/until/:date_until/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_date_since_rss ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_private_date_since_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_date_since_and_until_rss ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for/:search_terms_slug/rss.xml'
      search_rss.basket_search_private_date_since_and_until_rss ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for/:search_terms_slug/rss.xml'
    end

    search.with_options :action => 'for' do |search_for|
      search_for.basket_search_contributed_by ':urlified_name/search/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug'
      search_for.basket_search_private_contributed_by ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug'
      search_for.basket_search_related_to ':urlified_name/search/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for/:search_terms_slug'
      search_for.basket_search_private_related_to ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for/:search_terms_slug'
      search_for.basket_search_tagged ':urlified_name/search/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug'
      search_for.basket_search_private_tagged ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/for/:search_terms_slug'
      search_for.basket_search ':urlified_name/search/:controller_name_for_zoom_class/for/:search_terms_slug'
      search_for.basket_search_private ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/for/:search_terms_slug'
      search_for.basket_search_topic_type ':urlified_name/search/:controller_name_for_zoom_class/of/:topic_type/for/:search_terms_slug'
      search_for.basket_search_private_topic_type ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:topic_type/for/:search_terms_slug'
      search_for.basket_search_of_category ':urlified_name/search/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for/:search_terms_slug'
      search_for.basket_search_private_of_category ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for/:search_terms_slug'
      search_for.basket_search_date_until ':urlified_name/search/:controller_name_for_zoom_class/until/:date_until/for/:search_terms_slug'
      search_for.basket_search_private_date_until ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/until/:date_until/for/:search_terms_slug'
      search_for.basket_search_date_since ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/for/:search_terms_slug'
      search_for.basket_search_private_date_since ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/for/:search_terms_slug'
      search_for.basket_search_date_since_and_until ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for/:search_terms_slug'
      search_for.basket_search_private_date_since_and_until ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for/:search_terms_slug'

      search_for.with_options :search_terms => nil do |nil_search_terms|
        nil_search_terms.basket_search_contributed_by_empty ':urlified_name/search/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug'
        nil_search_terms.basket_search_private_contributed_by_empty ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/contributed_by/user/:contributor/for/:search_terms_slug'
        nil_search_terms.basket_search_related_to_empty ':urlified_name/search/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for'
        nil_search_terms.basket_search_private_related_to_empty ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/related_to/:source_controller_singular/:source_item/for'
        nil_search_terms.basket_search_tagged_empty ':urlified_name/search/:controller_name_for_zoom_class/tagged/:tag/for'
        nil_search_terms.basket_search_private_tagged_empty ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/tagged/:tag/for'
        nil_search_terms.basket_search_empty ':urlified_name/search/:controller_name_for_zoom_class/for'
        nil_search_terms.basket_search_private_empty ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/for'
        nil_search_terms.basket_search_topic_type ':urlified_name/search/:controller_name_for_zoom_class/of/:topic_type/for'
        nil_search_terms.basket_search_private_topic_type ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:topic_type/for'
        nil_search_terms.basket_search_of_category_empty ':urlified_name/search/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for'
        nil_search_terms.basket_search_private_of_category_empty ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/of/:extended_field/:limit_to_choice/for'
        nil_search_terms.basket_search_date_until ':urlified_name/search/:controller_name_for_zoom_class/until/:date_until/for'
        nil_search_terms.basket_search_private_date_until ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/until/:date_until/for'
        nil_search_terms.basket_search_date_since ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/for'
        nil_search_terms.basket_search_private_date_since ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/for'
        nil_search_terms.basket_search_date_since_and_until ':urlified_name/search/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for'
        nil_search_terms.basket_search_private_date_since_and_until ':urlified_name/search/:privacy_type/:controller_name_for_zoom_class/since/:date_since/until/:date_until/for'
      end
    end

  end

  # active_scaffold routes
  ACTIVE_SCAFFOLD_CONTROLLERS.each do |as_controller|
    map.resources as_controller.to_sym, :active_scaffold => true
  end

  map.basket_index ':urlified_name', :controller => "index_page", :action => 'index'
  map.basket_contact ':urlified_name/contact', :controller => "baskets", :action => 'contact'

  # James Stradling <james@katipo.co.nz>, 2008-04-15
  # Map private files to the PrivateFilesController
  # E.g. /documents/0000/0000/0011/Bio.txt
  map.private_file '/:type/:a/:b/:c/:filename.*formats', :controller => "private_files", :action => 'show'

  # Catch everything else
  map.basket_with_format ':urlified_name/:controller/:action/:id.:format'
  map.basket ':urlified_name/:controller/:action/:id'

  # Walter McGinnis, 2007-07-13
  # if the site isn't configured, we don't setup our full routes
  skip_configuration = Object.const_defined?(:SKIP_SYSTEM_CONFIGURATION)
  is_configured = false
  if !skip_configuration &&
        Object.const_defined?('SystemSetting') &&
        ActiveRecord::Base.connection.table_exists?('system_settings') &&
        SystemSetting.find(:all).size > 0
    is_configured = eval(SystemSetting.find_by_name('Is Configured').value)
  end
  if skip_configuration || is_configured
    # comment this line and uncomment the next after initial migration
    site_basket = Basket.find(1) unless skip_configuration # we skip a query here if running integration tests
    site_urlified_name = !site_basket.nil? ? site_basket.urlified_name : 'site'
    map.connect '', :controller => "index_page", :urlified_name => site_urlified_name
  else
    # not configured, redirect to homepage which is configuration page
    map.connect '', :controller => "configure", :urlified_name => 'site'
  end

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

