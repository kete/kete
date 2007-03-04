# load ruby-zoom Z39.50 interface lib
require 'zoom'
require "rexml/document"

class SearchController < ApplicationController
  include REXML

  layout "application" , :except => [:rss]

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

    @number_per_page = params[:number_or_results_per_page] ? params[:number_or_results_per_page].to_i : DEFAULT_RECORDS_PER_PAGE

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
    # @result_sets ||= session[:results_sets] || Hash.new

    populate_result_sets_for(@current_class,zoom_db)
  end

  def load_results(from_result_set)
    @results = Array.new

    if params[:action] == 'rss'
      @end_record = from_result_set.size
    else
      @end_record = from_result_set.size if from_result_set.size < @end_record
    end

    if from_result_set.size > 0
      still_image_results = Array.new

      # check if the result set is stale
      raw_results = Module.class_eval(@current_class).records_from_zoom_result_set( :result_set => from_result_set,
                                                                                    :start_record => @start_record,
                                                                                    :end_record => @end_record)
      # create a hash of link, title, description for each record
      raw_results.each do |raw_record|
        result_from_xml_hash = parse_from_xml_oai_dc(raw_record)
        logger.debug("what is result_from_xml_hash: #{result_from_xml_hash} ")
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
    if !@source_item.nil?
      # this looks in the dc_relation index in the z30.50 server
      # must be exact string
      # get the item
      query += "@and @attr 1=1026 @attr 4=3 \"#{url_for_dc_identifier(@source_item)}\" "
    end

    if !@tag.nil?
      # this looks in the dc_subject index in the z30.50 server
      # TODO: attr 1=21 was throwing unsupported
      # not sure why, see zebradb/tab/bib1.att
      # switch from "any" to "subject heading"
      query += "@and @attr 1=1016 \"#{@tag.name}\" "
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
      if @current_basket.urlified_name == 'site'
        query += "@attr 1=12 #{zoom_class} "
      else
        query += "@attr 1=12 @and #{@current_basket.urlified_name} #{zoom_class} "
      end
    else
      prepped_terms = Module.class_eval(zoom_class).split_to_search_terms(@search_terms)
      if @current_basket.urlified_name == 'site'
        query = "@and @attr 1=12 #{zoom_class} @attr 2=102 @attr 5=3 "
      else
        query = "@and @attr 1=12 @and #{@current_basket.urlified_name} #{zoom_class} @attr 2=102 @attr 5=3 "
      end

      # quote each term to handle phrases
      if !prepped_terms.blank?
        if prepped_terms.size > 1
          query += "@attr 1=1016 @and \"#{prepped_terms.join("\" \"")}\" "
        else
          # @and will break query if only single term
          query += "@attr 1=1016 \"#{prepped_terms.join("\" \"")}\" "
        end
      end
    end

    # this should go last because of "or contributor"
    if !@contributor.nil?
      # this looks in the dc_creator and dc_contributors indexes in the z30.50 server
      # must be exact string
      query += "@or @attr 1=1003 \"#{user_to_dc_creator_or_contributor(@contributor)}\" @attr 1=1020 \"#{user_to_dc_creator_or_contributor(@contributor)}\" "
      query = "@and " + query unless query[0,4] == "@and"
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
  # uses REXML rather than Hash.from_xml
  # for more control
  def parse_from_xml_oai_dc(zoom_record)
    record = Document.new zoom_record.xml

    # work through record and grab the values
    # we do this step because there may be a sub array for values
    # when the xml had multiples of the same element
    # we only want the first
    result_hash = Hash.new

    # we should be able to deduce the class
    # whether the result is local
    # and the object's id from the oai_identifier
    oai_identifier = record.elements.to_a("//header/identifier")[0].get_text.to_s

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
      # // xpath short cut to go right to element that matches
      # regardless of path that led to it
      field_value = record.elements.to_a("//dc:#{field[0]}")

      field_name = String.new
      if field[1].nil?
        field_name = field[0]
      else
        field_name = field[1]
      end

      result_hash[field_name] = field_value[0].get_text
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
    permit "site_admin of :current_basket" do
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
    permit "site_admin of :current_basket" do
      ZOOM_CLASSES.each do |zoom_class|
        Module.class_eval(zoom_class).find(:all).each {|item| prepare_and_save_to_zoom(item)}
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
    path_elements << 'rss'
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
                                                                   {:relate_to_topic => params[:relate_to_topic],
                                                                     :related_class =>params[:related_class].singularize}])
    render(:layout => "layouts/simple")
  end

end
