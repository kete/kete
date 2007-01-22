# load ruby-zoom Z39.50 interface lib
require 'zoom'
require "rexml/document"

class SearchController < ApplicationController
  include REXML

  layout "application" , :except => [:rss, :description]

  def index
    search
  end

  # TODO: catch zoom_db errors or zoom_db down
  # query our ZoomDbs for results, grab only the xml records for the results we need
  # TODO: possibly move result sets to session var
  def search
    # all returns all results for a class, contributor_id, or source_item (i.e. all related items to source)
    # it is the default if the search_terms parameter is not defined
    # however, if search_terms is defined (but not necessarily populated)
    # i.e. search_terms is not nil, but possibly blank
    # it overrides :all
    # in the case of search_terms and contributor_id or source_item both being present
    # the search is done with the limitations of the contributor_id or source_item
    # i.e. search for 'bob smith' within topics related to source_item 'daddy smith'
    if !params[:search_terms].nil?
      params[:all] = false
      else
      params[:all] = true
    end

    if params[:current_class].nil?
      params[:current_class] = DEFAULT_SEARCH_CLASS
    end

    @current_class = params[:current_class]

    # calculate where to start and end based on page
    if params[:page].nil?
      params[:page] = 1
    end

    @current_page = params[:page].to_i
    @next_page = @current_page + 1
    @previous_page = @current_page - 1

    if params[:number_or_results_per_page].nil?
      params[:number_or_results_per_page] = DEFAULT_RECORDS_PER_PAGE
    end

    @number_per_page = params[:number_or_results_per_page].to_i

    # 0 is the first index, so it's valid for start
    @start_record = @number_per_page * @current_page - @number_per_page
    @start = @start_record + 1
    @end_record = @number_per_page * @current_page

    @search_terms = String.new

    if params['search_terms'].blank? and !params[:all] then
      # TODO: have this message be derived from globalize
      flash[:notice] = "You haven't entered any search terms."
    else
      @search_terms = params[:search_terms]

      # TODO: skipping multiple source (federated) search for now
      zoom_db = ZoomDb.find_by_host_and_database_name('localhost','public')

      if @result_sets.nil?
        @result_sets = Hash.new
      end

      # iterate through all record types and build up a result set for each
      ZOOM_CLASSES.each do |zoom_class|
        if @result_sets[zoom_class].nil?

          query = String.new
          if !params[:source_item].blank?
            # this looks in the dc_relation index in the z30.50 server
            # must be exact string
            # get the item
            item = Module.class_eval(params[:source_item_class]).find(params[:source_item])
            query += "@and @attr 1=1026 @attr 4=3 \"#{url_for_dc_identifier(item)}\" "
          end

          # search_terms overrides :all, see above
          if params[:all]
            # default, special case, search all baskets for public topics and items
            # all others are limited to what is in their basket
            if @current_basket.urlified_name == 'site'
              query += "@attr 1=12 #{zoom_class} "
            else
              query += "@attr 1=12 @and #{@current_basket.urlified_name} #{zoom_class} "
            end
          else
            # process query and get a ZOOM::RecordSet back
            prepped_terms = Module.class_eval(zoom_class).split_to_search_terms(@search_terms)

            # this says, in essence, limit to objects in our class
            # and sort by dynamic relevance ranking (based on query)
            # and match partial words (truncated on either the left or right, i.e. both)
            # relevancee relies on our zoom dbs having it configured
            # kete zebra servers should be configured properly to use it
            # we may need to adjust when querying non-kete zoom_dbs (koha for example)
            # see comment above about current_basket
            if @current_basket.urlified_name == 'site'
              query = "@and @attr 1=12 #{zoom_class} @attr 2=102 @attr 5=3 "
            else
              query = "@and @attr 1=12 @and #{@current_basket.urlified_name} #{zoom_class} @attr 2=102 @attr 5=3 "
            end

            # quote each term to handle phrases
            if prepped_terms.size > 1
              query += "@attr 1=1016 @and \"#{prepped_terms.join("\" \"")}\" "
            else
              # @and will break query if only single term
              query += "@attr 1=1016 \"#{prepped_terms.join("\" \"")}\" "
            end
          end

          # this should go last because of "or contributor"
          if !params[:contributor_id].blank?
            # this looks in the dc_creator and dc_contributors indexes in the z30.50 server
            # must be exact string
            @contributor = User.find(params[:contributor_id])
            query += "@or @attr 1=1003 \"#{user_to_dc_creator_or_contributor(@contributor)}\" @attr 1=1020 \"#{user_to_dc_creator_or_contributor(@contributor)}\" "
            query = "@and " + query unless query[0,4] == "@and"
          end

          @result_sets[zoom_class] = Module.class_eval(zoom_class).process_query(:zoom_db => zoom_db,
                                                                                 :query => query)
        end
      end

      @last_page = @result_sets[@current_class].size / @number_per_page

      # we always want to round up if there is a remainder
      if (@result_sets[@current_class].size % @number_per_page) > 0
        @last_page += 1
      end

      @end_record = @result_sets[@current_class].size if @result_sets[@current_class].size < @end_record

      # results are limited to this page's display of search results
      # grab them from zoom
      @results = Array.new

      if @result_sets[@current_class].size > 0
        still_image_results = Array.new

        raw_results = Module.class_eval(@current_class).records_from_zoom_result_set( :result_set => @result_sets[@current_class],
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
                logger.debug("inside thumb assignment")
                result['image_file'] = thumb
              end
            end
          end
        end
      end
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

    # make this nil by defualt
    # overwrite for local results with actual thumbnail object
    result_hash['image_file'] = nil

    desired_fields = [['identifier', 'url'], ['title'], ['description', 'short_summary']]

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

  def description
    @headers["Content-Type"] = "text/xml"
    render 'opensearch/description'
  end
  # TODO: is this our rss feed for search results, even if we aren't using opensearch?
  def rss
    @headers["Content-Type"] = "text/xml"
    search
    render 'opensearch/rss'
  end
end
