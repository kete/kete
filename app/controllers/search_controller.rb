class SearchController < ApplicationController

  # Walter McGinnis, 2008-02-07
  # search forms never add anything to db
  # so don't need csrf protection, which is problematic with search forms
  # in kete
  skip_before_filter :verify_authenticity_token

  layout "application" , :except => [:rss]

  # we mimic caches_page so we have more control
  # note we specify extenstion .xml for rss url
  # in order to get caching to work correctly
  # i.e. served directly from webserver
  # rss caching is limited to "all" rather than "for"
  # i.e. no search_terms
  after_filter :write_rss_cache, :only => [:rss]
  # caches_page :rss

  # Reset slideshow object on new searches
  before_filter :reset_slideshow, :only => [:for, :all]

  # Ensure private RSS feeds are authenticated
  before_filter :authenticated_rss, :only => [:rss]

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
      @rss_tag_auto = rss_tag
      @rss_tag_link = rss_tag(:auto_detect => false)
      search
    else
      # TODO: redirect_to search form of the same url
    end
  end

  # this action is the action that relies on search_terms being defined
  # it can be thought of as "for/search_terms"
  def for
    # setup our variables derived from the url
    # several of these are valid if nil
    @search_terms = params[:search_terms]
    if @search_terms.nil?
      # TODO: have this message be derived from globalize
      flash[:notice] = "You haven't entered any search terms."
    else
      @rss_tag_auto = rss_tag
      @rss_tag_link = rss_tag(:auto_detect => false)
      search
    end
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

    # calculate where to start and end based on page
    @current_page = params[:page] ? params[:page].to_i : 1
    @next_page = @current_page + 1
    @previous_page = @current_page - 1

    if params[:number_of_results_per_page].nil?
      @number_per_page = session[:number_of_results_per_page] ? session[:number_of_results_per_page].to_i : DEFAULT_RECORDS_PER_PAGE
    else
      @number_per_page = params[:number_of_results_per_page].to_i
    end

    # update session with user preference for number of results per page
    store_number_of_results_per_page

    # 0 is the first index, so it's valid for start
    @start_record = @number_per_page * @current_page - @number_per_page
    @start = @start_record + 1
    @end_record = @number_per_page * @current_page
    # TODO: skipping multiple source (federated) search for now

    # James Stradling <james@katipo.co.nz> - 2008-05-02
    # Only allow private search if permitted
    if accessing_private_search_and_allowed?
      @privacy = "private"
      zoom_db_instance = "private"
    else
      zoom_db_instance = "public"
    end

    # Load the correct zoom_db instance and connect to it
    @search.zoom_db = ZoomDb.find_by_host_and_database_name('localhost', zoom_db_instance)
    @zoom_connection = @search.zoom_db.open_connection

    @result_sets = Hash.new

    # iterate through all record types and build up a result set for each
    if params[:related_class].nil?
      ZOOM_CLASSES.each do |zoom_class|
        populate_result_sets_for(zoom_class)
      end
    else
      # populate_result_sets_for(relate_to_class)
      populate_result_sets_for(only_valid_zoom_class(params[:related_class]).name)
    end
  end

  def rss

    @search = Search.new
    # changed from @headers for Rails 2.0 compliance
    response.headers["Content-Type"] = "application/xml; charset=utf-8"

    @controller_name_for_zoom_class = params[:controller_name_for_zoom_class] || zoom_class_controller(DEFAULT_SEARCH_CLASS)

    @current_class = zoom_class_from_controller(@controller_name_for_zoom_class)

    @source_controller_singular = params[:source_controller_singular]

    # the max we want returned for rss is always the latest created or modified 50
    # this will be be overwritten by the actual number of records that are available
    # if less than 50
    # see also sort_type
    @end_record = 50

    if !@source_controller_singular.nil?
      @source_class = zoom_class_from_controller(@source_controller_singular.pluralize)
      @source_item = Module.class_eval(@source_class).find(params[:source_item])
    else
      @source_class = nil
      @source_item = nil
    end

    @search_terms = params[:search_terms] ? params[:search_terms] : nil

    @tag = params[:tag] ? Tag.find(params[:tag]) : nil

    @contributor = params[:contributor] ? User.find(params[:contributor]) : nil

    # 0 is the first index, so it's valid for start
    @start_record = 0
    @start = 1
    
    # James - 2008-08-28
    # Only allow private search if permitted
    if accessing_private_search_and_allowed?
      zoom_db_instance = "private"
    else
      zoom_db_instance = "public"
    end

    # TODO: skipping multiple source (federated) search for now
    @search.zoom_db = ZoomDb.find_by_host_and_database_name('localhost', zoom_db_instance)

    @result_sets = Hash.new

    populate_result_sets_for(@current_class)
  end

  def authenticated_rss
    request.format = :xml
    params[:privacy_type] == "private" ? login_required : true
  end

  def load_results(from_result_set)
    @results = Array.new

    @end_record = from_result_set.size if from_result_set.size < @end_record

    if from_result_set.size > 0
      still_image_results = Array.new
      # protect against malformed requests
      # for a start record that is more than the numbers of matching records
      # not handling adjust @start_record in view
      # since it only seems to be bots that make the malformed request
      if @start_record > @end_record
        @start_record = 0
      end

      # get the raw xml results from zoom
      raw_results = Module.class_eval(@current_class).records_from_zoom_result_set( :result_set => from_result_set,
                                                                                    :start_record => @start_record,
                                                                                    :end_record => @end_record)
      # create a hash of link, title, description for each record
      raw_results.each do |raw_record|
        result_from_xml_hash = parse_from_xml_oai_dc(raw_record)
        @results << result_from_xml_hash

        # we want to load local thumbnails for image results
        # we'll collect the still_image_ids as keys and then run one query below
        if result_from_xml_hash['locally_hosted'] && result_from_xml_hash['class'] == 'StillImage'
          still_image_results << result_from_xml_hash['id']
        end
      end
      if @current_class == 'StillImage' || params[:related_class] == "StillImage"
        ImageFile.find_all_by_thumbnail('small_sq',
                                        :conditions => ["still_image_id in (?)", still_image_results]).each do |thumb|
          # now work through results array and add image_file
          # if appropriate
          @results.each do |result|
            if result['locally_hosted'] && result['id'].to_i == thumb.still_image_id
              result['image_file'] = thumb
            end
          end
        end
      end
    end
    @results = WillPaginate::Collection.new(@current_page, @number_per_page, from_result_set.size).concat(@results) unless params[:action] == 'rss'
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
    @search.pqf_query.kind_is(zoom_class, :operator => 'none')

    # limit baskets searched within, if appropriate
    unless searching_for_related_items?
      if params[:privacy_type] == 'private'

        # get the urlified_name for each basket the user has a role in
        # from their session
        basket_access_hash = logged_in? ? current_user.get_basket_permissions : Hash.new
        session[:has_access_on_baskets] = basket_access_hash
        basket_urlified_names = basket_access_hash.keys.collect { |key| key.to_s }

        if @current_basket == @site_basket and !basket_urlified_names.blank?
          @search.pqf_query.within(basket_urlified_names)
        elsif (@current_basket != @site_basket) and basket_urlified_names.member?(@current_basket.urlified_name)
          @search.pqf_query.within(@current_basket.urlified_name)
        end

      elsif @current_basket != @site_basket
        @search.pqf_query.within(@current_basket.urlified_name)
      end
    end

    # this looks in the dc_relation index in the z30.50 server
    # must be exact string
    # get the item
    @search.pqf_query.relations_include(url_for_dc_identifier(@source_item), :should_be_exact => true) if !@source_item.nil?

    # this looks in the dc_subject index in the z30.50 server
    @search.pqf_query.subjects_include(@tag.name) if !@tag.nil?


    # this should go last because of "or contributor"
    # this looks in the dc_creator and dc_contributors indexes in the z30.50 server
    # must be exact string
    @search.pqf_query.creators_or_contributors_include(@contributor.login) if !@contributor.nil?

    if !@search_terms.blank?
      # add the actual text search if there are search terms
      @search.pqf_query.title_or_any_text_includes(@search_terms)

      # this make searching for urls work
      @search.pqf_query.add_web_link_specific_query if zoom_class == 'WebLink'
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
    this_result_set = @search.zoom_db.process_query(:query => @search.pqf_query.to_s, :existing_connection => @zoom_connection)

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

  # grab the values we want from the zoom_record
  # and return them as a hash
  def parse_from_xml_oai_dc(zoom_record)
    # TODO: speed up more!
    # i still went with a middle ground and used REXML
    # since Hash.from_xml was falling over on multiple elements with the same name
    # break the record up into a hash with subhashes - partially done
    # which is faster than using XPath on an REXML doc
    # since we know the structure of the xml anyway
    # because of the instruct, we add an additional level
    record_parts = zoom_record.to_s.split("</header>")

    header_parts = record_parts[0].split("<header>")
    header_xml = '<header>' + header_parts[1] + '</header>'
    header = Hash.from_xml(header_xml)
    header = header['header']

    metadata_parts = record_parts[1].split("xsd\">")
    metadata_parts = metadata_parts[1].split("</oai_dc:dc>")

    dc_xml = metadata_parts[0].gsub("<dc:", "<").gsub("</dc:", "</")

    # record_xml = REXML::Document.new zoom_record.xml
    dublin_core = REXML::Document.new "<root>#{dc_xml}</root>"

    root = dublin_core.root

    # work through record and grab the values
    # we do this step because there may be a sub array for values
    # when the xml had multiples of the same element
    # we only want the first
    result_hash = Hash.new

    # we should be able to deduce the class
    # whether the result is local
    # and the object's id from the oai_identifier
    # oai_identifier = root.elements["header/identifier"].get_text.to_s
    oai_identifier = header["identifier"]

    local_re = Regexp.new("^#{ZoomDb.zoom_id_stub}")
    class_id_re = Regexp.new("([^:]+):([0-9]+)$")

    class_id_match = oai_identifier.match class_id_re
    # index 0 is whole matching string
    result_hash['class'] = class_id_match[1]
    result_hash['id'] = class_id_match[2]

    if oai_identifier =~ local_re
      result_hash['locally_hosted'] = true
    else
      result_hash['locally_hosted'] = false
    end

    # make this nil by default
    # overwrite for local results with actual thumbnail object
    result_hash['image_file'] = nil

    desired_fields = [['identifier', 'url'], ['title'], ['description', 'short_summary'], ['date']]

    desired_fields.each do |field|
      # TODO: this xpath is expensive, replace if possible!
      # moving the record to a hash is much faster
      # but i'm stuck on how to get "from_xml" to handle namespace stuff
      # // xpath short cut to go right to element that matches
      # regardless of path that led to it
      # field_value = root.elements["//dc:#{field[0]}"]
      field_value = root.elements[field[0]]
      # field_value = dublin_core[field[0]]
      # field_value = dc_attributes["oai_dc:dc"]["dc:#{field[0]}"]

      field_name = String.new
      if field[1].nil?
        field_name = field[0]
      else
        field_name = field[1]
      end

      # value_for_return_hash = field_value
      value_for_return_hash = field_value.text

      # short_summary may have some html
      # which is being handed back as rexml object
      # rather than string
      if field_name == 'short_summary'
        value_for_return_hash = prepare_short_summary(value_for_return_hash.to_s)
      end

      result_hash[field_name] = value_for_return_hash
    end

    return result_hash
  end

  def redirect_to_default_all
    redirect_to basket_all_url(:controller_name_for_zoom_class => zoom_class_controller(DEFAULT_SEARCH_CLASS))
  end

  # takes search_terms from form
  # and redirects to .../for/seach-term1-and-search-term2 url
  def terms_to_page_url_redirect
    controller_name = params[:controller_name_for_zoom_class].nil? ? \
      zoom_class_controller(DEFAULT_SEARCH_CLASS) : params[:controller_name_for_zoom_class]

    location_hash = { :controller_name_for_zoom_class => controller_name,
                      :existing_array_string => params[:existing_array_string],
                      :sort_direction => params[:sort_direction],
                      :sort_type => params[:sort_type],
                      :authenticity_token => nil }

    if params[:privacy_type] == 'private'
      location_hash.merge!({ :privacy_type => params[:privacy_type] })
    end

    if !params[:search_terms].blank?
      location_hash.merge!({ :search_terms_slug => to_search_terms_slug(params[:search_terms]),
                             :search_terms => params[:search_terms],
                             :action => 'for' })
    else
      location_hash.merge!({ :action => 'all' })
    end

    if !params[:tag].blank?
      location_hash.merge!({ :tag => params[:tag] })
    end

    if !params[:contributor].blank?
      location_hash.merge!({ :contributor => params[:contributor] })
    end

    logger.info("terms_to_page_url_redirect hash: " + location_hash.inspect)

    redirect_to url_for(location_hash)
  end

  def to_search_terms_slug(search_terms)
    require 'unicode'

    # Find all phrases enclosed in quotes and pull
    # them into a flat array of phrases
    search_terms = search_terms.to_s
    double_phrases = search_terms.scan(/"(.*?)"/).flatten
    single_phrases = search_terms.scan(/'(.*?)'/).flatten

    # Remove those phrases from the original string
    left_over = search_terms.gsub(/"(.*?)"/, "").squeeze(" ").strip
    left_over = left_over.gsub(/'(.*?)'/, "").squeeze(" ").strip

    # Break up the remaining keywords on whitespace
    keywords = left_over.split(/ /)

    terms = keywords + double_phrases + single_phrases

    slug = terms.join('-and-')

    slug = Unicode::normalize_KD(slug+"-").downcase.gsub(/[^a-z0-9\s_-]+/,'').gsub(/[\s_-]+/,'-')[0..-2]
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
        prepare_and_save_to_zoom(item)

        # Rebuild
        # Should be unnecessary.
        # if item.has_private_version?
        #   item.private_version do
        #     prepare_and_save_to_zoom(item)
        #   end
        # end

        if items_count == 1
          first_item = item
        end
        items_count += 1
      end
      flash[:notice] = "ZOOM indexes rebuilt"
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

  # this takes the configuration and uses it to start a backgroundrb worker
  # to do the actual rebuild work on zebra
  def rebuild_zoom_index
    @zoom_class = !params[:zoom_class].blank? ? params[:zoom_class] : 'all'
    @start_id = !params[:start].blank? && @zoom_class != 'all' ? params[:start] : 'first'
    @end_id = !params[:end].blank? && @zoom_class != 'all' ? params[:end] : 'last'
    @skip_existing = !params[:skip_existing].blank? ? params[:skip_existing] : false
    @skip_private = !params[:skip_private].blank? ? params[:skip_private] : false
    @clear_zebra = !params[:clear_zebra].blank? ? params[:clear_zebra] : false

    @worker_type = 'zoom_index_rebuild_worker'

    import_request = { :host => request.host,
      :protocol => request.protocol,
      :request_uri => request.request_uri }

    @worker_running = false
    # only one rebuild should be running at a time
    unless backgroundrb_is_running?(@worker_type)
      MiddleMan.new_worker( :worker => @worker_type, :worker_key => @worker_type.to_s )
      MiddleMan.worker(@worker_type, @worker_type.to_s).async_do_work( :arg => { :zoom_class => @zoom_class,
                                                                         :start_id => @start_id,
                                                                         :end_id => @end_id,
                                                                         :skip_existing => @skip_existing,
                                                                         :skip_private => @skip_private,
                                                                         :clear_zebra => @clear_zebra,
                                                                         :import_request => import_request } )
      @worker_running = true
    else
      flash[:notice] = 'There is another search record rebuild running at this time.  Please try again later.'
    end
  end

  # this reports progress back to the tech admin
  # on how the backgroundrb worker is doing
  # with the search record rebuild
  def check_rebuild_status
    if !request.xhr?
      flash[:notice] = 'You need javascript enabled for this feature.'
      redirect_to 'setup_rebuild'
    else
      @worker_type = 'zoom_index_rebuild_worker'
      status = MiddleMan.worker(@worker_type, @worker_type.to_s).ask_result(:results)
      begin
        if !status.blank?
          current_zoom_class = status[:current_zoom_class] || 'Topic'
          records_processed = status[:records_processed]
          records_failed = status[:records_failed]
          records_skipped = status[:records_skipped]

          render :update do |page|

            page.replace_html 'time_started', "<p>Started at #{status[:do_work_time]}</p>"

            page.replace_html 'processing_zoom_class', "<p>Working on #{zoom_class_plural_humanize(current_zoom_class)}</p>"

            if records_processed > 0
              page.replace_html 'report_records_processed', "<p>#{records_processed} records processed</p>"
            end

            if records_failed > 0
              failed_message = "<p>#{records_failed} records failed</p>"
              failed_message += "<p>These maybe private or pending moderation records, depending on the case.  See log/backgroundrb... for details.</p>"
              page.replace_html 'report_records_failed', failed_message
            end

            if records_skipped > 0
              page.replace_html 'report_records_skipped', "<p>#{records_skipped} records skipped</p>"
            end

            logger.info("after record reports")
            if status[:done_with_do_work] == true or !status[:error].blank?
              logger.info("inside done")
              done_message = "All records processed "

              if !status[:error].blank?
                logger.info("error not blank")
                done_message = "There was a problem with the rebuild: #{status[:error]}<p><b>The rebuild has been stopped</b></p>"
              end
              done_message += " at #{status[:done_with_do_work_time]}."
              page.hide("spinner")
              page.replace_html 'done', done_message
              page.replace_html 'exit', '<p>' + link_to('Browse records', :action => 'all') + '</p>'
            end
          end
        else
          message = "Rebuild failed "
          message +=  "at #{status[:done_with_do_work_time]}." unless status[:done_with_do_work_time].blank?
          flash[:notice] = message
          render :update do |page|
            page.hide("spinner")
            page.replace_html 'done', '<p>' + message + ' ' + link_to('Return to Rebuild Set up', :action => 'setup_rebuild') + '</p>'
          end
        end
      rescue
        # we aren't getting to this point, might be nested begin/rescue
        # check background logs for error
        rebuild_error = !status.blank? ? status[:error] : "rebuild worker not running anymore?"
        logger.info(rebuild_error)
        message = "Rebuild failed. #{rebuild_error}"
        message += " - #{$!}" unless $!.blank?
        message +=  " at #{status[:done_with_do_work_time]}." unless status[:done_with_do_work_time].blank?
        flash[:notice] = message
        render :update do |page|
          page.hide("spinner")
          page.replace_html 'done', '<p>' + message + ' ' + link_to('Return to Rebuild Set up', :action => 'setup_rebuild') + '</p>'
        end
      end
    end
  end

  def rss_tag(options = {:auto_detect => true})
    auto_detect = options[:auto_detect]

    tag = String.new

    if auto_detect
      tag = "<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" "
    else
      tag = "<a "
    end

    tag += "href=\""+ request.protocol + request.host
    # split everything before the query string and the query string
    url = request.request_uri.split('?')

    # now split the path up and add rss to it
    path_elements = url[0].split('/')
    path_elements << 'rss.xml'
    new_path = path_elements.join('/')
    tag +=  new_path
    # if there is a query string, tack it on the end
    if !url[1].nil?
      logger.debug("what is query string: #{url[1].to_s}")
      tag += "?#{url[1].to_s}"
    end
    if auto_detect
      tag +=  "\" />"
    else
      tag += "\">" # A tag has a closing </a>
    end
  end

  # used to choose a topic as homepage for a basket
  # Kieran - 2008-07-07
  # SLOW. Not sure why at this point, but it's 99% rendering, not DB.
  def find_index
    @current_basket = Basket.find(params[:current_basket_id])
    @site_basket = 0 # leaving this default (unset) makes all baskets topics show up when in site basket
                     # comment out that assignment if you wish to allow topics from other baskets to show up in the site basket homepage selection
    @current_homepage = @current_basket.index_topic

    case params[:function]
      when "find"
        @results = Array.new
        @search_terms = params[:search_terms]
        search unless @search_terms.blank?
        unless @results.empty?
          if !@current_homepage.nil?
            @results.reject! { |result| (result["id"].to_i == @current_homepage.id) }
          end
          @results.collect! { |result| Module.class_eval(result["class"]).find(result["id"]) }
        end
      when "change"
        @new_homepage_topic = Topic.find(params[:homepage_topic_id])
        @success = (@current_homepage != @new_homepage_topic) ? @current_basket.update_index_topic(@new_homepage_topic) : true
        if @success
          flash[:notice] = "Homepage topic changed successfully"
          @current_homepage = @current_basket.index_topic
        else
          flash[:error] = "Problem changing Homepage topic"
        end
    end
    render :action => 'homepage_topic_form', :layout => "popup_dialog"
  end

  # James - 2008-06-13
  # SLOW. Not sure why at this point, but it's 99% rendering, not DB.
  def find_related
    @current_topic = Topic.find(params[:relate_to_topic])
    related_class_is_topic = params[:related_class] == "Topic" ? true : false
    # this will throw exception if passed in related_class isn't valid
    related_class = only_valid_zoom_class(params[:related_class])
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
      @verb = "Existing"
      @next_action = "unlink"
      @results = existing
    when "restore"
      @verb = "Restore"
      @next_action = "link"

      # Find resulting items through deleted relationships
      @results = ContentItemRelation::Deleted.find_all_by_topic_id_and_related_item_type(@current_topic,
                                                                                         related_class_name).collect { |r| related_class.find(r.related_item_id) }
      if related_class_is_topic
        @results += ContentItemRelation::Deleted.find_all_by_related_item_id_and_related_item_type(@current_topic,
                                                                                                   'Topic').collect { |r| Topic.find(r.topic_id) }
      end
    when "add"
      @verb = "Add"
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
        valid_result_ids = @results.collect { |result| result["id"].to_i }
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

  def write_rss_cache
    # start of caching code, work in progress
    request_string = request.request_uri
    if request_string.split("?")[1].nil? and request_string.scan("contributed_by").blank? and request_string.scan("related_to").blank? and request_string.scan("tagged").blank?
      # mimic page caching
      # by writing the file to fs under public
      cache_page(response.body,params)
    end
  end

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
    prepare_and_save_to_zoom(item)

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

    results = @results.map{ |r| r['url'] }

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

end
