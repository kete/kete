  KeteApp::Application.routes.draw do

  ####################################################
  ####################################################
  # prepend locale to all routes
  # * see routing-filter gem for details
  # * it prepends the :locale to all routes e.g. /de/ping

  # * it is not clear if this gem is still required in rails 3. We are
  #   keeping it around until we figure out whether the same stuff can be}
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

  # EOIN/ROB: rabid temp test and "feature not done" routes.
  get '/cruft/ping' => 'cruft#index'
  get '/cruft/not_implemented' => 'cruft#not_implemented', :as => :not_implemented

  #####################################################
  #### monitoring tools ###############################
  #
  ## to make sure the rails process is answering
  #match 'uptime.txt' => 'index_page#uptime'
  ## to make sure that the db is answering
  #match 'db_uptime.txt' => 'index_page#db_uptime'
  ## to make sure that the zebra is answering
  #match 'zebra_uptime.txt' => 'index_page#zebra_uptime'
  ## to make sure that the backgroundrb is answering
  #match 'bdrb_uptime.txt' => 'index_page#bdrb_uptime'
  ## to make sure that registration is valid
  #match 'validate_kete_net_link.xml' => 'index_page#validate_kete_net_link'
  ## for search engines, ask them not to go to certain places
  #match 'robots.txt' => 'index_page#robots'
  ## for opensearch compatible clients
  #match 'opensearchdescription.xml' => 'index_page#opensearchdescription'

  ####################################################
  ####################################################


  ####################################################
  # Various RSS feeds not associated with search #####

  # RABID: we have disabled RSS Feeds
  # match ':urlified_name/moderate/rss.:format' => 'moderate#rss', :as => :basket_moderate_rss
  # match ':urlified_name/members/rss.:format' => 'members#rss', :as => :basket_moderate_rss

  ####################################################
  ####################################################

  get   ':urlified_name/account/index' => 'account#index'
  match ':urlified_name/account/signup' => 'account#signup', via: [:get, :post]
  match ':urlified_name/account/login' => 'account#login', via: [:get, :post]
  get   ':urlified_name/account/disclaimer/:id' => 'account#disclaimer'
  match ':urlified_name/account/show_captcha' => 'account#show_captcha'
  match ':urlified_name/account/forgot_password' => 'account#forgot_password'

  ####################################################
  # terrible hacks ###################################

  match 'site/index_page/selected_image' => 'index_page#selected_image'
  get 'site/moderate/list' => 'moderate#list'
  get ':urlified_name/members/list' => 'members#list'
  get 'site/importers/list' => 'importers#list'

  match ':urlified_name/contact' => 'baskets#contact', :as => :basket_contact

  # Link Helpers
  # ############
  #
  # Since the views in this app date from Rails 2 they do not make much use the
  # *_path and *_url helpers that routes create.

  # #url_for
  #     url_for([model.basket, model])
  #     url_for(urlified_name: basket.urlified_name, controller: 'foos', action: 'blah', id: 33)
  #     url_for(action: 'newthing') # url_for will tweak the current_url if you don't supply all the required args
  # #link_to
  #     link_to "Some model ", url_for(model.basket, model.first)
  #     link_to "Some model ", basket_topic_path(model.basket, model.first)

  # We adjust the name of the route (via `as:`) in cases where the controller
  # name does not match the model name because
  #     url_for(some_model)
  # does its magic by looking up the class of `some_model` and finding a path
  # helper to match. If the route name does not match the model name this will
  # not work.

  scope '/:urlified_name', as: :basket do

    scope '/search', as: :search do
      post 'for'            => 'search#for'
      post 'all'            => 'search#all'
      post 'tagged'         => 'search#tagged'
      post 'related_to'     => 'search#related_to'
      post 'contributed_by' => 'search#contributed_by'
    end

    resources :baskets, only: [:edit] do
      member do
        post :add_tags # TaggingController
      end
      collection do
        get :list
      end
    end

    resources :topics do
      member do
        get :history # FlaggingController
        get :preview # FlaggingController
        post :add_tags # TaggingController
      end
      collection do
        get :list
      end
    end

    resources :images, as: :still_image do
      member do
        get :history # FlaggingController
        get :preview # FlaggingController
        post :add_tags # TaggingController
      end
      collection do
        get :list
      end
    end

    resources :audio, as: :audio_recording do
      member do
        get :history # FlaggingController
        get :preview # FlaggingController
        post :add_tags # TaggingController
      end
      collection do
        get :list
      end
    end

    resources :video do
      member do
        get :history # FlaggingController
        get :preview # FlaggingController
        post :add_tags # TaggingController
      end
      collection do
        get :list
      end
    end

    resources :web_links do
      member do
        get :history # FlaggingController
        get :preview # FlaggingController
        post :add_tags # TaggingController
      end
      collection do
        get :list
      end
    end

    resources :documents do
      member do
        get :history # FlaggingController
        get :preview # FlaggingController
        post :add_tags # TaggingController
      end
      collection do
        get :list
      end
    end

    resources :comments

    resources :tags, only: [:index, :show] do
      collection do
        get :list
      end
    end

  end


  ####################################################
  ####################################################

  # active_scaffold routes
  ACTIVE_SCAFFOLD_CONTROLLERS.each do |as_controller|
    resources as_controller.to_sym, active_scaffold: true, path_prefix: ':urlified_name'
  end

  match ':urlified_name' => 'index_page#index', :as => :basket_index

  # James Stradling <james@katipo.co.nz>, 2008-04-15
  # Map private files to the PrivateFilesController
  # E.g. /documents/0000/0000/0011/Bio.txt
  match '/:type/:a/:b/:c/:filename.*formats' => 'private_files#show', :as => :private_file

  # Catch everything else
  # match ':urlified_name/:controller/:action/:id.:format' => ':controller#:action', :as => :basket_with_format
  match ':urlified_name(/:controller(/:action(/:id)))'         => ':controller#:action', :as => :basket

  root to: 'index_page#index', urlified_name: 'site'

  # If none of the above routes match, send the browser to application#rescue_404
  match '*path' => 'application#rescue_404' unless Rails.env.development?
end
