# load ruby-zoom Z39.50 interface lib
require 'zoom'
require "rexml/document"

class SearchController < ApplicationController
  include REXML

  layout "application" , :except => [:rss, :description]

  def index
    search
  end

  # query our ZoomDbs for results, grab only the Kete objects we need
  def search

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

    if params['search_terms'].nil? then
      # TODO: have this message be derived from globalize
      flash[:notice] = "You haven't entered any search terms."
    else
      # TODO: rejigger search terms in form so that "" and '' work
      @search_terms = params[:search_terms]

      # TODO: skipping multiple source (federated) search for now
      # should really search public zoom_db by class
      zoom_db = ZoomDb.find_by_host_and_database_name('localhost','public')

      if @result_sets.nil?
        @result_sets = Hash.new
      end

       ZOOM_CLASSES.each do |zoom_class|
        if @result_sets[zoom_class].nil?
          # process query and get a ZOOM::RecordSet back
          prepped_terms = Module.class_eval(zoom_class).split_to_search_terms(@search_terms)

          # TODO: this is what we will need to adjust when we have kete scope
          # this says, in essence, limit to objects in our class
          # and sort by dynamic relevance ranking (based on query)
          # and match partial words (truncated on either the left or right, i.e. both)
          # TODO: relevancee appears broken, but this may be our zoom db, rather than query
          query = "@and @attr 1=12 #{zoom_class} @attr 2=102 @attr 5=3 "
          # quote each term to handle phrases
          if prepped_terms.size > 1
            query += "@attr 1=1016 @and \"#{prepped_terms.join("\" \"")}\""
          else
            # @and will break query if only single term
            query += "@attr 1=1016 \"#{prepped_terms.join("\" \"")}\""
          end

          @result_sets[zoom_class] = Module.class_eval(zoom_class).process_query( :zoom_db => zoom_db,
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
      raw_results = Module.class_eval(@current_class).records_from_zoom_result_set( :result_set => @result_sets[@current_class],
                                                                                    :start_record => @start_record,
                                                                                    :end_record => @end_record)
      @results = Array.new
      # create a hash of link, title, description for each record
      raw_results.each do |raw_record|
        result_from_xml_hash = parse_from_xml_oai_dc(raw_record)
        @results << result_from_xml_hash
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
