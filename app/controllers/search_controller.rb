# load ruby-zoom Z39.50 interface lib
require 'zoom'
require "rexml/document"

class SearchController < ApplicationController
  ZOOM_BOOLEAN_OPERATORS = ['and', 'or', 'not']

  layout "application" , :except => [:rss]

  # we mimic caches_page so we have more control
  # note we specify extenstion .xml for rss url
  # in order to get caching to work correctly
  # i.e. served directly from webserver
  # rss caching is limited to "all" rather than "for"
  # i.e. no search_terms
  after_filter :write_rss_cache, :only => [:rss]
  # caches_page :rss

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
    if params[:relate_to_topic]
      render(:layout => "layouts/simple") # get it so the popup version has no layout
    end
  end

  def search
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
    zoom_db = ZoomDb.find_by_host_and_database_name('localhost','public')

    @result_sets = Hash.new

    # iterate through all record types and build up a result set for each
    if params[:relate_to_class].nil?
      ZOOM_CLASSES.each do |zoom_class|
        populate_result_sets_for(zoom_class,zoom_db)
      end
    else
      populate_result_sets_for(relate_to_class,zoom_db)
    end

    @last_page = @result_sets[@current_class].size / @number_per_page

    # we always want to round up if there is a remainder
    if (@result_sets[@current_class].size % @number_per_page) > 0
      @last_page += 1
    end
  end

  def rss
    @headers["Content-Type"] = "application/xml; charset=utf-8"

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

    @tag = params[:tag] ? Tag.find(params[:tag]) : nil

    @contributor = params[:contributor] ? User.find(params[:contributor]) : nil

    # 0 is the first index, so it's valid for start
    @start_record = 0
    @start = 1

    # TODO: skipping multiple source (federated) search for now
    zoom_db = ZoomDb.find_by_host_and_database_name('localhost','public')

    @result_sets = Hash.new

    populate_result_sets_for(@current_class,zoom_db)
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
      if @current_class == 'StillImage'
        ImageFile.find_all_by_thumbnail('small_sq', :conditions => ["still_image_id in (?)", still_image_results]).each do |thumb|
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
  end

  def populate_result_sets_for(zoom_class,zoom_db)
    query = String.new
    query_operators = String.new
    sort_type = 'none'

    # potential elements of query
    # zoom_class and optionally basket
    # search_terms which search both title attribute and all content attribute
    # source_item for things related to item
    # tag for things tagged with the tag/subject
    # contributor for things contributed to or created by a user
    # sort_type for last_modified

    if @current_basket.urlified_name == 'site'
      query += "@attr 1=12 #{zoom_class} "
    else
      query += "@attr 1=12 @and #{@current_basket.urlified_name} #{zoom_class} "
    end

    if !@source_item.nil?
      # this looks in the dc_relation index in the z30.50 server
      # must be exact string
      # get the item
      query += "@attr 1=1026 @attr 4=3 \"#{url_for_dc_identifier(@source_item)}\" "
      query_operators += "@and "
    end

    if !@tag.nil?
      # this looks in the dc_subject index in the z30.50 server
      query += "@attr 1=21 \"#{@tag.name}\" "
      query_operators += "@and "
    end

    # this should go last because of "or contributor"
    if !@contributor.nil?
      # this looks in the dc_creator and dc_contributors indexes in the z30.50 server
      # must be exact string
      query += "@or @attr 1=1003 \"#{user_to_dc_creator_or_contributor(@contributor)}\" @attr 1=1020 \"#{user_to_dc_creator_or_contributor(@contributor)}\" "
      query_operators += "@and "
    end

    # process query and get a ZOOM::RecordSet back

    # this says, in essence, limit to objects in our class
    # and sort by dynamic relevance ranking (based on query)
    # and match partial words (truncated on either the left or right, i.e. both)
    # relevancee relies on our zoom dbs having it configured
    # kete zebra servers should be configured properly to use it
    # we may need to adjust when querying non-kete zoom_dbs (koha for example)
    # see comment above about current_basket

    if @search_terms.nil?
      # this is an "all" search
      # sort by date last modified, i.e. oai_datestamp
      sort_type = 'last_modified'
    else
      # if this rss, we want last_modified to be taken into account
      # otherwise, strictly relevance
      if params[:action] == 'rss'
        sort_type = 'last_modified'
      end

      # add the dynamic relevance ranking
      # allowing for incomplete search terms
      # and fuzzy (one character misspelled)
      query += "@attr 2=102 @attr 5=3 @attr 5=103 "

      # possibly move this to acts_as_zoom
      # handles case were someone is searching for a url
      # there may be other special characters to handle
      # but this seems to do the trick
      @search_terms = @search_terms.gsub("/", "\/")

      prepped_terms = Module.class_eval(zoom_class).split_to_search_terms(@search_terms)

      # quote each term to handle phrases
      if !prepped_terms.blank?
        if prepped_terms.size > 1
          # give precedence in relevance
          # to items that have the terms in their title
          # by adding title to attribute and "or" all attribute
          # rather than just searching all attribute
          title_query = "@or @attr 1=4 "
          all_content_query = "@attr 1=1016 "

          # work through terms
          # if there is a boolean operator specified
          # add it to the correct spot
          # if not specified add another "@and"

          term_count = 1
          terms_array = Array.new
          operators_array = Array.new
          query_starts_with_not = false
          last_term_an_operator = false
          prepped_terms.each do |term|
            # if first term is boolean operator "not"
            # then replace the @and for this element of the query with @not
            # all other boolean operators are treated as normal words if first term
            if term_count == 1
              if term.downcase == 'not'
                query_starts_with_not = true
              else
                terms_array << term
              end
            else
              if term_count > 1
                # in the rare case that @not has replaced
                # @and at the front of the whole query
                # and this is the second term
                # skip adding a boolean operator
                if query_starts_with_not == true and term_count == 2
                  # this just treats even terms found in
                  # ZOOM_BOOLEAN_OPERATORS as regular words
                  # since their placement makes them meaningless as boolean operators
                  terms_array << term
                else
                  if ZOOM_BOOLEAN_OPERATORS.include?(term)
                    # we got ourselves an operator
                    operators_array << "@#{term}"
                    last_term_an_operator = true
                  else
                    # just a plain term
                    if last_term_an_operator == false
                      # need to add an operator
                      # assume "and" since none-specified
                      operators_array << "@and "
                    end

                    terms_array << term
                    last_term_an_operator = false
                  end
                end
              end
            end

            term_count += 1
          end

          # handle case where the user has enterd two or more operators in a row
          # we just subtract one from the beginning of operators_array
          while operators_array.size >= terms_array.size
            operators_array.delete_at(0)
          end

          if operators_array.size > 0
            title_query += operators_array.join(" ") + " "
            all_content_query += operators_array.join(" ") + " "
          end

          if query_starts_with_not == true
            query_operators += "@not "
          else
            query_operators += "@and "
          end

          title_query += "\"" + terms_array.join("\" \"") + "\" "
          all_content_query += "\"" + terms_array.join("\" \"") + "\" "
          query += title_query + all_content_query
        else
          # @and will break query if only single term
          query += "@or @attr 1=4 \"#{prepped_terms.join("\" \"")}\" @attr 1=1016 \"#{prepped_terms.join("\" \"")}\" "
          query_operators += "@and "
        end
      end
    end

    query = query_operators + query

    case sort_type
    when 'last_modified'
      query = "@or " + query + "@attr 7=2 @attr 1=1012 0"
    end

    this_result_set = Module.class_eval(zoom_class).process_query(:zoom_db => zoom_db,
                                                                  :query => query)

    @result_sets[zoom_class] = this_result_set

    if zoom_class == @current_class
      # results are limited to this page's display of search results
      # grab them from zoom
      load_results(this_result_set)
    end

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
    if params[:controller_name_for_zoom_class].nil?
      redirect_to url_for(:overwrite_params => {:controller_name_for_zoom_class => zoom_class_controller(DEFAULT_SEARCH_CLASS), :action => 'for', :search_terms_slug => to_search_terms_slug(params[:search_terms]), :commit => nil, :existing_relations => params[:existing_array_string]})
    else
      redirect_to url_for(:overwrite_params => {:action => 'for', :search_terms_slug => to_search_terms_slug(params[:search_terms]), :commit => nil})
    end

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
      first_item_class = String.new
      first_item_id = String.new
      items_to_rebuild.each do |item_class_and_id|
        item_array = item_class_and_id.split("-")
        if items_count == 1
          first_item_class = item_array[0]
          first_item_id = item_array[1]
        end
        item = Module.class_eval(item_array[0]).find(item_array[1])
        prepare_and_save_to_zoom(item)
        items_count += 1
      end
      flash[:notice] = "ZOOM indexes rebuilt"
      # first item in list should be self
      redirect_to :action => 'show', :controller => zoom_class_controller(first_item_class), :id => first_item_id
    end
  end

  # this probably won't scale, only use for demo right now
  def rebuild_zoom_index
    permit "site_admin" do
      if !params[:zoom_class].nil?
        Module.class_eval(params[:zoom_class]).find(:all).each {|item| prepare_and_save_to_zoom(item)}
      else
        ZOOM_CLASSES.each do |zoom_class|
          Module.class_eval(zoom_class).find(:all).each {|item| prepare_and_save_to_zoom(item)}
        end
      end
      render :text => "ZOOM index rebuilt"
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

  def find_related
    @existing_relations = ContentItemRelation.find(:all,
                                                   :conditions => ["topic_id = :relate_to_topic and related_item_type = :related_class",
                                                                   { :relate_to_topic => params[:relate_to_topic],
                                                                     :related_class =>params[:related_class].singularize}])
    render(:layout => "layouts/simple")
  end

  # keep the user's preference for number of results per page
  # stored in a session cookie
  # so they don't have to reset it everytime they go to new search results
  def store_number_of_results_per_page
      session[:number_of_results_per_page] = @number_per_page
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

  def prepare_short_summary(source_string,length = 30,end_string = '')
    source_string = source_string.to_s
    # length is how many words, rather than characters
    words = source_string.split()
    short_summary = words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
  end
end
