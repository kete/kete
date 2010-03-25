class SearchController < ApplicationController

  # Walter McGinnis, 2008-02-07
  # search forms never add anything to db
  # so don't need csrf protection, which is problematic with search forms
  # in kete
  skip_before_filter :verify_authenticity_token

  # James - 2008-09-03
  # Check for access before running private searches
  before_filter :require_login_if_private_search, :only => [:rss, :for, :all]
  before_filter :private_search_authorisation, :only => [:rss, :for, :all]

  # RSS caching has now moved to fragement caching
  # for finer grain caching (and to suit a larger number of cases)
  # after_filter :write_rss_cache, :only => [:rss]

  # Reset slideshow object on new searches
  before_filter :reset_slideshow, :only => [:for, :all]

  # After running a search, store the results in a session
  # for slideshow functionality.
  after_filter :store_results_for_slideshow, :only => [:for, :all]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :rebuild_zoom_index ],
         :redirect_to => { :action => :index }

  # these search actions should only be done by tech admins at this time
  permit "tech_admin", :only => [ :setup_rebuild, :rebuild_zoom_index, :check_rebuild_status ]

  def index
  end

  def list
  end

  def clear
    if params[:search_id].to_i > 0
      clear_users_previous_searches(params[:search_id].to_i)
      flash[:notice] = t('search_controller.clear.selected_search_removed')
      redirect_to :action => 'list'
    else
      clear_users_previous_searches
      flash[:notice] = t('search_controller.clear.previous_searches_removed')
      redirect_to "/" # go to the homepage to avoid another search
    end
  end

  # REFACTOR SCRATCH:
  # split search action into "all", "for", and "index"
  # index: where somone can enter search terms
  # all: search results that are not based on search_terms
  # for: results for search terms
  # search currently handles results "for" these types of results
  #
  # bare search terms with no other criteria
  #
  # all items of a type - criteria only zoom_class_to_controller_name
  #
  # all items contributed by a user - criteria zoom_class_to_controller_name, user.id
  #
  # all items related to an item - criteria zoom_class_to_controller_name, source_item_class, source_item_id
  #
  # all items with tag - criteria zoom_class_to_controller_name, tag
  #
  # -> search within results of "all items..."

  # REFACTOR TODOS:
  # TODO: catch zoom_db errors or zoom_db down

  # query our ZoomDbs for results, grab only the xml records for the results we need
  # all returns all results for a class, contributor_id, or source_item (i.e. all related items to source)
  # it is the default if the search_terms parameter is not defined
  def all
    @search_terms = params[:search_terms]
    if @search_terms.nil?
      setup_rss
      search
    else
      # TODO: redirect_to search form of the same url
    end

    setup_map if params[:view_as] == 'map'

    # if zoom class isn't valid, @results is nil,
    # so lets rescue with a 404 in this case
    rescue_404 if @results.nil?

    # if everything went well, lets save this search for the current_user
    save_current_search
  end

  # this action is the action that relies on search_terms being defined
  # it can be thought of as "for/search_terms"
  def for
    # setup our variables derived from the url
    # several of these are valid if nil
    @search_terms = params[:search_terms]
    if @search_terms.nil?
      flash[:notice] = t('search_controller.for.no_search_terms')
    else
      setup_rss
      search
    end

    setup_map if params[:view_as] == 'map'

    # if zoom class isn't valid, @results is nil,
    # so lets rescue with a 404 in this case
    rescue_404 if @results.nil?

    # if everything went well, lets save this search for the current_user
    save_current_search
  end

  def search
    @search = Search.new

    # all returns all results for a class, contributor_id, or source_item (i.e. all related items to source)
    # it is the default if the search_terms parameter is not defined
    # however, if search_terms is defined (but not necessarily populated)
    # i.e. search_terms is not nil, but possibly blank
    # it overrides :all
    # in the case of search_terms and contributor_id or source_item both being present
    # the search is done with the limitations of the contributor_id or source_item
    # i.e. search for 'bob smith' within topics related to source_item 'daddy smith'

    @controller_name_for_zoom_class = params[:controller_name_for_zoom_class] || zoom_class_controller(DEFAULT_SEARCH_CLASS)

    @current_class = zoom_class_from_controller(@controller_name_for_zoom_class)

    @source_controller_singular = params[:source_controller_singular]

    if !@source_controller_singular.nil?
      @source_class = zoom_class_from_controller(@source_controller_singular.pluralize)
      @source_item = Module.class_eval(@source_class).find(params[:source_item])
    else
      @source_class = nil
      @source_item = nil
    end

    @tag = params[:tag] ? Tag.find(params[:tag]) : nil

    @contributor = params[:contributor] ? User.find(params[:contributor]) : nil

    @limit_to_choice = Choice.from_id_or_value(params[:limit_to_choice]) if params[:limit_to_choice]

    @extended_field = ExtendedField.from_id_or_label(params[:extended_field]) if params[:extended_field]
    @all_choices = true unless @extended_field

    @topic_type = TopicType.from_urlified_name(params[:topic_type]).first if params[:topic_type]

    @date_since = params[:date_since].blank? ? nil : params[:date_since]
    @date_until = params[:date_until].blank? ? nil : params[:date_until]

    # calculate where to start and end based on page
    @current_page = (params[:page] && params[:page].to_i > 0) ? params[:page].to_i : 1
    @next_page = @current_page + 1
    @previous_page = @current_page - 1

    # rss is always is set at 50 per page unless limit if specified
    if is_rss?
      @number_per_page = (params[:count] || 50).to_i
    else
      # otherwise we fallback to default constant
      # unless user has specifically chosen a different number
      if params[:number_of_results_per_page].blank?
        @number_per_page = session[:number_of_results_per_page] ? session[:number_of_results_per_page].to_i : DEFAULT_RECORDS_PER_PAGE
      else
        @number_per_page = params[:number_of_results_per_page].to_i
      end
    end

    # update session with user preference for number of results per page
    store_number_of_results_per_page unless is_rss?

    # 0 is the first index, so it's valid for start
    @start_record = @number_per_page * @current_page - @number_per_page
    @start = @start_record + 1
    @end_record = @number_per_page * @current_page

    # James Stradling <james@katipo.co.nz> - 2008-05-02
    # Only allow private search if permitted
    @privacy = "private" if is_a_private_search?

    # Load the correct zoom_db instance and connect to it
    @search.zoom_db = ZoomDb.find_by_database_name(zoom_database)
    @zoom_connection = @search.zoom_db.open_connection

    @result_sets = Hash.new

    # iterate through all record types and build up a result set for each
    if params[:related_class].nil?
      # rss doesn't use :related_class
      # but is limited to querying one class
      if is_rss?
        populate_result_sets_for(@current_class)
      else
        ZOOM_CLASSES.each do |zoom_class|
          populate_result_sets_for(zoom_class)
        end
      end
    else
      # populate_result_sets_for(relate_to_class)
      populate_result_sets_for(only_valid_zoom_class(params[:related_class]).name)
    end
  end

  # search method now is smart enough to handle rss situation
  # especially now that we have pagination in rss (ur, atom?)
  def rss
    @search_terms = params[:search_terms]

    # set up the cache key, which handles our params beyond basket, action, and controller
    @cache_key_hash = Hash.new

    @cache_key_hash[:page] = (params[:page] || 1).to_i
    @cache_key_hash[:number_per_page] = (params[:count] || 50).to_i

    @cache_key_hash[:privacy] = "private" if is_a_private_search?

    # set the following, if they exist in params
    relevant_keys = %w( search_terms_slug search_terms tag contributor limit_to_choice source_controller_singular source_item )
    relevant_keys.each do |key|
      key = key.to_sym
      @cache_key_hash[key] = params[key] unless params[key].blank?
    end

    # no need to hit zebra and parse records
    # if we already have the cached rss
    unless has_all_rss_fragments?(@cache_key_hash)
      @search = Search.new
      search
    end

    respond_to do |format|
      format.xml
    end
  end

  def load_results(from_result_set)
    @results = Array.new

    # protect against malformed requests
    # for a start record that is more than the numbers of matching records, return a 404
    # since it only seems to be bots that make the malformed request
    @end_record = from_result_set.size if from_result_set.size < @end_record
    if @start_record > @end_record
      rescue_404
      return false
    end

    if from_result_set.size > 0
      # get the raw xml results from zoom
      raw_results = from_result_set.records_from(:start_record => @start_record,
                                                 :end_record => @end_record)
      # create a hash of link, title, description for each record
      raw_results.each do |raw_record|
        result_from_xml_hash = parse_from_xml_in(raw_record)
        @results << result_from_xml_hash
      end
    end
    @results = WillPaginate::Collection.new(@current_page,
                                            @number_per_page,
                                            from_result_set.size).concat(@results)
  end

  def populate_result_sets_for(zoom_class)
    # potential elements of query
    # zoom_class and optionally basket
    # search_terms which search both title attribute and all content attribute
    # source_item for things related to item
    # tag for things tagged with the tag/subject
    # contributor for things contributed to or created by a user
    # sort_type for last_modified

    # limit query to within our zoom_class
    unless zoom_class == 'Combined'
      @search.pqf_query.kind_is(zoom_class, :operator => 'none')
    else
      # we have to put something into this inorder to get results
      @search.pqf_query.kind_is("oai", :operator => 'none')
    end

    # limit baskets searched within
    if searching_for_related_items?
      @search.pqf_query.within(authorised_basket_names) if is_a_private_search? && !@site_admin
    else
      @topics_outside_of_this_basket ||= true
      if @current_basket != @site_basket || !@topics_outside_of_this_basket
        @search.pqf_query.within(@current_basket.urlified_name)
      else
        @search.pqf_query.within(authorised_basket_names) if is_a_private_search? && !@site_admin
      end
    end

    # this looks in the dc_relation index in the z30.50 server
    # must be exact string
    # get the item
    # we use should_be_exact rather than _equals_completely method here
    # because relations have a key index on them and should be exact uses that
    @search.pqf_query.relations_include(url_for_dc_identifier(@source_item, { :force_http => true, :minimal => true }), :should_be_exact => true) if !@source_item.nil?

    # this looks in the dc_subject index in the z30.50 server
    @search.pqf_query.subjects_equals_completely("#{@tag.name}") if !@tag.nil?

    # this should go last because of "or contributor"
    # this looks in the dc_creator and dc_contributors indexes in the z30.50 server
    # must be exact string
    @search.pqf_query.creators_or_contributors_equals_completely("'#{@contributor.login}'") if !@contributor.nil?

    # James
    # Extended Field choice searching mechanisms

    # Handle searching against a specific extended field.
    begin
      dc_element = @extended_field ? @extended_field.xml_element_name.gsub(/^(dc:)/, "") : nil
    rescue

      # We need to handle the case where no xml_element_name has been given.
      dc_element = "description"
    end

    plural_aliased_dc_methods = %w(relation subject creator contributor)

    if plural_aliased_dc_methods.member?(dc_element)

      # Since these attributes are mapped as plural, we need to ensure we use the correct method in the PqfQuery model.
      @search.pqf_query.send("#{dc_element.pluralize}_include", "':#{@limit_to_choice.value}:'") unless @limit_to_choice.blank?

    elsif PqfQuery::ATTRIBUTE_SPECS.member?(dc_element)
      @search.pqf_query.send("#{dc_element}_include", "':#{@limit_to_choice.value}:'") unless @limit_to_choice.blank?
    else

      # Since the DC attribute is either bogus or non-existent, do the search against all search with demarcated terms
      @search.pqf_query.any_text_include("':#{@limit_to_choice.value}:'") unless @limit_to_choice.blank?
    end

    @search.pqf_query.coverage_equals_completely("#{@topic_type.name}") if !@topic_type.nil?

    @search.pqf_query.date_on_or_after(parse_date_into_zoom_compatible_format(@date_since, :beginning)) if !@date_since.nil?
    # until means "up to this date" so beginning of year or month is what we want
    # previously this was "on or before", which really meant "through the end of this year or month"
    @search.pqf_query.date_before(parse_date_into_zoom_compatible_format(@date_until, :beginning)) if !@date_until.nil?

    # Normal search terms..

    if !@search_terms.blank?
      # add the actual text search if there are search terms
      @search.pqf_query.title_or_any_text_includes(@search_terms)

      # this make searching for urls work
      @search.pqf_query.add_web_link_specific_query if zoom_class == 'WebLink'
    end

    # Date searching is a special thing,
    # but existing sort params take precendence
    # then search term sorting
    if @date_since.present? || @date_until.present?
      if @search_terms.blank?
        params[:sort_type] ||= 'date'

        # date based search direction has some specific logic
        # depending on combination of parameters
        if @date_since.present?
          # we want oldest first if since is specified
          # either in combination with until
          # or on its own
          params[:sort_direction] ||= 'reverse'
        elsif @date_since.blank? && @date_until.present?
          # we want youngest results if only until is specified
          # as they will be closest to the until parameter date
          params[:sort_direction] ||= nil
        end
      end
    end

    sort_type = @current_basket.settings[:sort_order_default]
    sort_direction = @current_basket.settings[:sort_direction_reversed_default]
    search_sort_type = (params[:sort_type].blank? and !sort_type.blank?) ? sort_type : params[:sort_type]
    search_sort_direction = (params[:sort_type].blank? and !sort_direction.blank?) ? sort_direction : params[:sort_direction]
    @search.add_sort_to_query_if_needed(:user_specified => search_sort_type,
                                        :direction => search_sort_direction,
                                        :action => params[:action],
                                        :search_terms => @search_terms)

    logger.debug("what is query: " + @search.pqf_query.to_s.inspect)

    this_result_set = @search.zoom_db.process_query(query_options)

    @result_sets[zoom_class] = this_result_set

    # results are limited to this page's display of search results, or to the related
    # class, if passed in.
    if zoom_class == @current_class || !params[:related_class].blank?

      # grab them from zoom
      load_results(this_result_set)
    end

    # now that we have results, reset pqf_query
    @search.pqf_query = PqfQuery.new
  end

  def redirect_to_default_all
    redirect_to basket_all_url(:controller_name_for_zoom_class => zoom_class_controller(DEFAULT_SEARCH_CLASS))
  end

  # takes search_terms from form
  # and redirects to .../for/seach-term1-and-search-term2 url
  def terms_to_page_url_redirect
    basket_name = params[:target_basket].nil? ? \
      params[:urlified_name] : params[:target_basket]

    controller_name = params[:controller_name_for_zoom_class].nil? ? \
      zoom_class_controller(DEFAULT_SEARCH_CLASS) : params[:controller_name_for_zoom_class]

    location_hash = { :urlified_name => basket_name,
                      :controller_name_for_zoom_class => controller_name,
                      :existing_array_string => params[:existing_array_string],

                      # sort_direction is a boolean, so we need to force a blank value if not
                      # sent through to ensure the users choice of direction is maintained
                      :sort_direction => params[:sort_direction] || '',

                      :sort_type => params[:sort_type],
                      :limit_to_choice => params[:limit_to_choice],
                      :extended_field => params[:extended_field],
                      :authenticity_token => nil }

    if is_a_private_search?
      location_hash.merge!({ :privacy_type => params[:privacy_type] })
    end

    if !params[:search_terms].blank?
      # we are searching
      location_hash.merge!({ :search_terms_slug => to_search_terms_slug(params[:search_terms]),
                             :search_terms => params[:search_terms],
                             :action => 'for' })
    else
      # we are viewing all
      location_hash.merge!({ :action => 'all' })
    end

    # If we're searching by tag, this will be set
    if !params[:tag].blank?
      location_hash.merge!({ :tag => params[:tag] })
    end

    # If we're searching by contributor, this will be set
    if !params[:contributor].blank?
      location_hash.merge!({ :contributor => params[:contributor] })
    end

    # If we're searching by relation, these will be set
    if !params[:source_controller_singular].blank?
      location_hash.merge!({ :source_controller_singular => params[:source_controller_singular] })
    end
    if !params[:source_item].blank?
      location_hash.merge!({ :source_item => params[:source_item] })
    end

    # James
    # Handle choice specific searching.
    if !params[:limit_to_choice].blank?
      location_hash.merge!({ :limit_to_choice => params[:limit_to_choice] })
    end
    if !params[:extended_field].blank?
      location_hash.merge({ :extended_field => params[:extended_field] })
    end

    if !params[:topic_type].blank?
      location_hash.merge!({ :topic_type => params[:topic_type] })
    end

    if !params[:date_since].blank?
      location_hash.merge!({ :date_since => params[:date_since] })
    end
    if !params[:date_until].blank?
      location_hash.merge!({ :date_until => params[:date_until] })
    end

    logger.debug("terms_to_page_url_redirect hash: " + location_hash.inspect)

    redirect_to url_for(location_hash)
  end

  def to_search_terms_slug(search_terms)
    # This method should return the following:
    #  quotes phrases:       word_after_word
    #  non-quoted phrases:   word+after+word
    # Join both types with +. i.e.
    #  this 'is quoted' you see -> this+you+see+is_quoted

    # For multi lingual URLs
    require 'unicode'

    # Find all phrases enclosed in quotes and pull them into a flat array of phrases
    search_terms = search_terms.to_s

    # While we need to preserver ampersands in the search terms within single/double quotes,
    # in the search slug, this isn't necessary, and without it, you end up with this-_-that
    # rather than the desired this-and-that, so before splitting it up, convert & to and
    search_terms = search_terms.gsub('&', 'and')

    double_phrases = search_terms.scan(/"(.*?)"/).flatten
    single_phrases = search_terms.scan(/'(.*?)'/).flatten

    # Remove those phrases from the original string
    left_over = search_terms.gsub(/"(.*?)"/, "").squeeze(" ").strip
    left_over = left_over.gsub(/'(.*?)'/, "").squeeze(" ").strip

    # Break up the remaining keywords on whitespace
    keywords = left_over.split(/ /)

    # join everything into one big terms array
    terms = keywords + double_phrases + single_phrases

    # Join each search term with +, change everything that isn't a number into an underscore
    # and cut mulitple underscores in a row down to just one
    slug = terms.join('+').gsub(/[^\w\+_-]/, '_').gsub(/_+/, '_')

    # Lets escape any characters that might cause invalid urls, normalize it, and downcase
    Unicode::normalize_KD(slug.escape).downcase
  end

  # expects a comma separated list of zoom_class-id
  # for the objects to be reindexed
  def rebuild_zoom_for_items
    permit "site_admin" do
      items_to_rebuild = params[:items_to_rebuild].split(",")
      items_count = 1
      first_item = nil
      items_to_rebuild.each do |item_class_and_id|
        item_array = item_class_and_id.split("-")
        item = only_valid_zoom_class(item_array[0]).find(item_array[1])
        item.prepare_and_save_to_zoom
        if items_count == 1
          first_item = item
        end
        items_count += 1
      end
      flash[:notice] = t('search_controller.rebuild_zoom_for_items.zoom_rebuilt')
      # first item in list should be self
      redirect_to_show_for(first_item)
    end
  end

  # actions for rebuilding search records
  # see filters and permissions for security towards top of code
  include WorkerControllerHelpers
  # this is the form for tech admins
  # to configure the rebuild_zoom_index action
  def setup_rebuild
  end

  # rebuild_zoom_index action now lives in lib/worker_controller_helpers.rb

  # this reports progress back to the tech admin
  # on how the backgroundrb worker is doing
  # with the search record rebuild
  def check_rebuild_status
    if !request.xhr?
      flash[:notice] = t('search_controller.check_rebuild_status.need_js')
      redirect_to 'setup_rebuild'
    else
      @worker_type = 'zoom_index_rebuild_worker'
      @worker_key = params[:worker_key]
      status = MiddleMan.worker(@worker_type, @worker_key).ask_result(:results)
      begin
        if !status.blank?
          current_zoom_class = status[:current_zoom_class] || 'Topic'
          records_processed = status[:records_processed]
          records_failed = status[:records_failed]
          records_skipped = status[:records_skipped]

          render :update do |page|

            page.replace_html 'time_started', "<p>#{t('search_controller.check_rebuild_status.started_at', :start_time => status[:do_work_time])}</p>"

            page.replace_html 'processing_zoom_class', "<p>#{t('search_controller.check_rebuild_status.working_on', :zoom_class => zoom_class_plural_humanize(current_zoom_class))}</p>"

            if records_processed > 0
              page.replace_html 'report_records_processed', "<p>#{t('search_controller.check_rebuild_status.amount_processed', :amount => records_processed)}</p>"
            end

            if records_failed > 0
              failed_message = "<p>#{t('search_controller.check_rebuild_status.records_failed', :amount => records_failed)}</p>"
              failed_message += "<p>#{t('search_controller.check_rebuild_status.failed_reason')}</p>"
              page.replace_html 'report_records_failed', failed_message
            end

            if records_skipped > 0
              page.replace_html 'report_records_skipped', "<p>#{t('search_controller.check_rebuild_status.records_skipped', :amount => records_skipped)}</p>"
            end

            logger.info("after record reports")
            if status[:done_with_do_work] == true or !status[:error].blank?
              logger.info("inside done")
              done_message = t('search_controller.check_rebuild_status.all_processed')

              if !status[:error].blank?
                logger.info("error not blank")
                done_message = t('search_controller.check_rebuild_status.rebuild_error', :error => status[:error])
              end
              done_message += t('search_controller.check_rebuild_status.finished_at', :end_time => status[:done_with_do_work_time])
              page.hide("spinner")
              page.replace_html 'done', done_message
              page.replace_html 'exit', '<p>' + link_to(t('search_controller.check_rebuild_status.browse'), { :action => 'all', :controller_name_for_zoom_class => 'topics' }) + '</p>'
            end
          end
        else
          message = t('search_controller.check_rebuild_status.rebuild_failed')
          message +=  t('search_controller.check_rebuild_status.finished_at', :end_time => status[:done_with_do_work_time]) unless status[:done_with_do_work_time].blank?
          flash[:notice] = message
          render :update do |page|
            page.hide("spinner")
            page.replace_html 'done', '<p>' + message + ' ' + link_to(t('search_controller.check_rebuild_status.return_to_rebuild'), :action => 'setup_rebuild') + '</p>'
          end
        end
      rescue
        # we aren't getting to this point, might be nested begin/rescue
        # check background logs for error
        rebuild_error = !status.blank? ? status[:error] : t('search_controller.check_rebuild_status.not_running')
        logger.info(rebuild_error)
        message = t('search_controller.check_rebuild_status.rebuild_failed', :error => rebuild_error)
        message += " - #{$!}" unless $!.blank?
        message +=  t('search_controller.check_rebuild_status.finished_at', :end_time => status[:done_with_do_work_time]) unless status.nil? || status[:done_with_do_work_time].blank?
        flash[:notice] = message
        render :update do |page|
          page.hide("spinner")
          page.replace_html 'done', '<p>' + message + ' ' + link_to(t('search_controller.check_rebuild_status.return_to_rebuild'), :action => 'setup_rebuild') + '</p>'
        end
      end
    end
  end

  # used to choose a topic as homepage for a basket
  # Kieran - 2008-07-07
  # SLOW. Not sure why at this point, but it's 99% rendering, not DB.
  def find_index
    @current_basket = Basket.find(params[:current_basket_id])
    @topics_outside_of_this_basket = false  # turn this to true if you want to allow the Site basket
                                            # homepage to be an About basket topic for example
    @current_homepage = @current_basket.index_topic

    case params[:function]
      when "find"
        @results = Array.new
        @search_terms = params[:search_terms]
        search unless @search_terms.blank?
        unless @results.empty?
          if !@current_homepage.nil?
            @results.reject! { |result| (result[:id].to_i == @current_homepage.id) }
          end
          @results.collect! { |result| Module.class_eval(result[:class]).find(result[:id]) }
        end
      when "change"
        @new_homepage_topic = Topic.find(params[:homepage_topic_id])
        version_after_update = @new_homepage_topic.max_version + 1
        @homepage_different = (@current_homepage != @new_homepage_topic)
        # if the homepage isn't different, don't do anything or it mucks up versions, just return true so it passes
        if @homepage_different
          # update the homepage topic. Unfortunatly, the method created new topic versions for both the old and new homepage topics
          # and because the basket doesn't have flagging controls, we can't save it without the version
          # so instead, we have to make sure we assign contributors below, one for the old homepage topic, and one for the new
          # homepage topic, which is taken care of in the method after_successful_zoom_item_update
          @current_basket.update_index_topic(@new_homepage_topic)
          unless @current_homepage.nil?
            # if there was a previous homepage topic, it'll be given a new version by update_index_topic
            # so we need to add a contributor to prevent 500 errors on the history page of the topic
            # we also have to pass in the version + 1, because we are working from an old copy of the previous homepage topic
            # and the version is out of date by this stage, and calling reload on it will load the new homepage topic, not the old
            @current_homepage.add_as_contributor(current_user, (@current_homepage.version + 1))
          end
          # this adds a contributor to the new homepage topic version, and clears the relevant show caches.
          # clearing of the basket homepage index page caches are taken care of in a before filter in application.rb
          after_successful_zoom_item_update(@new_homepage_topic, version_after_update)
          @successful = true
        else
          @successful = true
        end
        if @successful
          flash[:notice] = t('search_controller.find_index.changed')
          # we assign the current_homepage instance var to the new homepage,
          # because its used in the template we populate the search fields and links
          @current_homepage = @new_homepage_topic
        else
          flash[:error] = t('search_controller.find_index.failed')
        end
    end
    render :action => 'homepage_topic_form', :layout => "popup_dialog"
  end

  # James - 2008-06-13
  # SLOW. Not sure why at this point, but it's 99% rendering, not DB.
  def find_related
    @current_topic = Topic.find(params[:relate_to_topic])
    @related_class = (params[:related_class] || "Topic")
    related_class_is_topic = @related_class == "Topic" ? true : false
    # this will throw exception if passed in related_class isn't valid
    related_class = only_valid_zoom_class(@related_class)
    related_class_name = related_class.name

    # there is an instance variable for each zoom_class
    # that can be related to a topic through content_item_relations
    # topics related to topics are a special case
    # the method name is called 'related_topics'
    method_name_for_related_items = related_class_is_topic ? 'related_topics' : related_class_name.tableize

    # Look up existing relationships, we use these in 2 out of three functions
    existing = @current_topic.send(method_name_for_related_items) unless params[:function] == 'restore'

    case params[:function]
    when "remove"
      @verb = t('search_controller.find_related.remove')
      @next_action = "unlink"
      @results = existing
    when "restore"
      @verb = t('search_controller.find_related.restore')
      @next_action = "link"

      # Find resulting items through deleted relationships
      @results = ContentItemRelation::Deleted.find_all_by_topic_id_and_related_item_type(@current_topic, related_class_name) \
                                             .collect { |r| related_class.find(r.related_item_id) }
      if related_class_is_topic
        @results += ContentItemRelation::Deleted.find_all_by_related_item_id_and_related_item_type(@current_topic, 'Topic') \
                                                .collect { |r| Topic.find(r.topic_id) }
      end
    when "add"
      @verb = t('search_controller.find_related.add')
      @next_action = "link"
      @results = Array.new

      # Run a search if necessary
      # this will update @results
      @search_terms = params[:search_terms]
      unless @search_terms.blank?
        search

        # Store pagination information, we'll need this later
        pagination_methods = ['total_entries', 'total_pages', 'current_page',
                              'previous_page', 'next_page']

        pagination_methods = pagination_methods.inject(Hash.new) do |hash, method_name|
          hash[method_name] = @results.send(method_name)
          hash
        end
      end

      # existing is all one class
      # compare against results ids
      @existing_ids = existing.collect { |existing_item| existing_item.id }

      # Ensure results do not include already linked items or the current item.
      unless @results.empty?
        # grab result ids to optimize look up of local objects
        valid_result_ids = @results.collect { |result| result[:id].to_i }
        @results = related_class.find(valid_result_ids)

        # Don't include the current topic in the results
        @results.reject! { |obj| obj == @current_topic } if related_class_is_topic

        # Define pagination methods in the array again.
        pagination_methods.each_key do |method_name|

          eval \
          "class << @results
            define_method('#{method_name}') do
              #{pagination_methods[method_name]}
            end
          end"

        end
      end
    end

    render :action => 'related_form', :layout => "popup_dialog"
  end

  # keep the user's preference for number of results per page
  # stored in a session cookie
  # so they don't have to reset it everytime they go to new search results
  def store_number_of_results_per_page
      session[:number_of_results_per_page] = @number_per_page
  end

  # James - 2008-07-04
  # Specialist method for slideshow paging functionality..
  def slideshow_page_load
    @search_terms = params[:search_terms]

    # Make sure the search method knows which search action we're mimicking.
    params[:action] = slideshow.search_params[:search_action]

    # Run the search
    search

    # Update the slideshow object in session
    store_results_for_slideshow

    # Redirect to the first or last object on the page, depending on the direction we're going..
    url = (params[:direction] == "up") ? session[:slideshow][:results].first : session[:slideshow][:results].last

    # Preserve the image view size when redirecting to the next page.
    url = append_options_to_url(url, "view_size=#{slideshow.image_view_size}") if slideshow.image_view_size
    redirect_to(url)
  end

  def clear_slideshow
    session[:slideshow] = nil
    redirect_to url_for(params[:return_to])
  end

  private

  # James Stradling <james@katipo.co.nz> - 2008-05-02
  # Refactored to use acts_as_zoom#has_appropriate_records?
  #### DEPRECIATED?
  def zoom_update_and_test(item,zoom_db)
    item_class = item.class.name

    if !session[:skip_existing].nil? and session[:skip_existing] == true
      # test if it's in there first
      if item.has_appropriate_zoom_records?
        return "skipping existing: search record exists: #{item_class} : #{item.id}"
      end
    end

    # if not, add it
    item.prepare_and_save_to_zoom

    # confirm that it's now available
    if item.has_appropriate_zoom_records?
      return "successfully updated search: #{item_class} : #{item.id}"
    else
      return "failed to add to search: #{item_class} : #{item.id} not found in search index or perhaps the item is pending."
    end
  end

  # Check whether we are searching for candidate related items or not
  def searching_for_related_items?
    params[:controller] == "search" and params[:action] == "find_related"
  end

  def searching_for_index_topics?
    params[:controller] == "search" and params[:action] == "find_index"
  end

  # James - 2008-07-04
  # Store the elements need to reproduce the search in a session
  def store_results_for_slideshow

    # if @results_sets is emtpy, then @result_sets[@current_class] is nil so we have
    # to stop here if thats the case, or we get a 500 error calling .size below
    return if @result_sets.nil? || @result_sets[@current_class].nil? || @displaying_error

    results = @results.map{ |r| r[:url] }

    total_results = @result_sets[@current_class].size

    # We want to retain the original search action name for future use
    altered_params = params
    altered_params.merge!(:search_action => params[:action]) unless params[:action] == "slideshow_page_load"

    if slideshow.results.nil?
      slideshow.search_params = { "page" => "1" }
    end

    slideshow.results         = results
    slideshow.total           = total_results
    slideshow.total_pages     = @results.total_pages
    slideshow.current_page    = @results.current_page
    slideshow.number_per_page = @number_per_page
    slideshow.search_params   = altered_params

    logger.debug("Stored results for page #{slideshow.current_page}: #{slideshow.results.join(", ")}")
    logger.debug("Original parameters where: #{params.inspect}")
    logger.debug("Storing parameters for search: #{slideshow.search_params.inspect}")
  end

  def reset_slideshow
    session[:slideshow] = nil
  end

  # Walter McGinnis, 2008-09-29
  # separate out login filter to better handle http auth for rss
  def require_login_if_private_search
    if is_a_private_search?
      login_required
    else
      # this is a public search, no login required
      return true
    end
  end

  # James - 2008-09-03
  # Check for authorisation when performing private searches
  def private_search_authorisation

    # Allow all public searches
    return true unless is_a_private_search?

    if @current_basket == @site_basket and !authorised_basket_names.empty?

      # In the case of the site basket, the only baskets that are searched privately are those
      # which the user is a member of (using the same logic as above).
      # For this reason, no unauthorised searching will take place, so it is safe to continue.

      true
    elsif authorised_basket_names.member?(@current_basket.urlified_name)

      # In the case of a specific, non-site basket, the search is limited to this basket, and
      # we're checking if they're a member here. So, it is safe to continue now.

      true
    else

      # Otherwise, they do not have permission and have probably forgotten to log in.
      logger.info "A user who was #{logged_in? ? "" : "not "}logged was denied access to a private search."

      respond_to do |format|
        format.html do
          redirect_to DEFAULT_REDIRECTION_HASH
        end
        format.xml do
          render :text => "<error>#{t('search_controller.private_search_authorisation.forbidden')}</error>", :status => 403
        end
      end

    end
  end

  # create and configure our map object using ym4r
  # requires the div "map" in view
  def setup_map
    if @results
      @map = GMap.new("map")
      # Use the larger pan/zoom control but disable the map type
      # selector
      @map.control_init(:large_map => true, :map_type => true)

      # * is essential for this to work
      @map.center_zoom_on_points_init(*@coordinates_for_results)
      logger.debug("what is map:" + @map.inspect)
    end
  end

  # Check if we are meant to be running a private search #=> Boolean
  def is_a_private_search?
    @private_search ||= params[:privacy_type] == "private"
  end

  # Which zoom database to use #=> String (public/private)
  def zoom_database
    @zoom_database ||= is_a_private_search? ? "private" : "public"
  end

  # Ensure RSS errors are handled with a suitable response
  # For instance, RSS should trigger a http_auth_basic response, while normal searches
  # should trigger a redirect to login page
  def set_xml_format_before_auth
    request.format = :xml
  end

  def is_rss?
    params[:action] == 'rss'
  end

  helper_method :is_rss?

  private

  # set up the results specific rss links
  # we now have combined version of each search/browse results RSS
  # in addition to the zoom class specific rss
  def setup_rss
    @rss_tag_auto = [rss_tag, rss_tag(:combined => true)]
    @rss_tag_link = [rss_tag(:auto_detect => false), rss_tag(:auto_detect => false, :combined => true)]
  end
end
