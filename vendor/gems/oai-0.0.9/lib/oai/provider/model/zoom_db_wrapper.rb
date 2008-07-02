require 'oai'
require 'oai/provider'
# using http://oai.rubyforge.org/svn/trunk/lib/oai/provider/model/activerecord_wrapper.rb
# as code to base this on
# assumes that ZOOM::Record has been extended to have a to_oai method
# see acts_as_zoom/lib/record.rb plugin code for this
# also needs Kete's classes of Search and PqfQuery
require 'search'
require 'pqf_query'
module OAI::Provider
  # = OAI::Provider::ZoomDbWrapper
  #
  # This class wraps ZoomDb and delegates all of the record
  # selection/retrieval to the ZoomDb model.
  #
  # Finds against ZoomDb return ResultSet objects (i.e. objects that are agregates of zoom records)
  # rather than individual records.
  #
  # The records are assumed to already be in OAI Dublin Core XML.
  #
  # RESUMPTION TOKENS AREN'T CURRENTLY SUPPORTED
  # commented out code left in for reference
  # for possible future implementation if needed
  class ZoomDbWrapper < Model

    attr_reader :zoom_db

    def initialize(zoom_db, options={})
      @search = Search.new
      @search.zoom_db = zoom_db

      @timestamp_field = options.delete(:timestamp_field) || 'complete_datestamp'

      @limit = options.delete(:limit)

      unless options.empty?
        raise ArgumentError.new(
                                "Unsupported options [#{options.keys.join(', ')}]"
                                )
      end
    end

    # define the earliest, latest methods that only have one difference in code
    ['earliest', 'latest'].each do |method_name|
      sort_direction = method_name == 'earliest' ? 'reverse' : 'none'
      define_method(method_name) do
        find(:first,
             :sort_spec => 'last_modified',
             :sort_direction => sort_direction).send(@timestamp_field)
      end
    end

    def sets
      # sets will return static oai_pmh_repository_sets +
      # generate sets from dynamic oai_pmh_repository_sets specs
      # oai_set has name, description, spec
      @search.zoom_db.sets if @search.zoom_db.respond_to?(:sets)
    end

    def find(selector, options={})
      # return next_set(options[:resumption_token]) if options[:resumption_token]

      update_query_with(selector, options)
      @result_set = @search.zoom_db.process_query(:query => @search.pqf_query.to_s)

      # clear @search.pqf_query, so that next query doesn't just add to it
      @search.pqf_query = PqfQuery.new

      total = @result_set.size

      # all and first at this point
      # or an identifier
      # when :all && @limit && total > @limit
      # select_partial(ResumptionToken.new(options.merge({:last => 0})))
      case selector
      when :first
        @result_set[0]
      else
        # update_query_with(selector, options) should handle limiting query
        # to only the single record if this is a GetRecord request
        # return all records
        if @result_set.size > 1 || selector == :all
          @result_set.records
        else
          @result_set[0]
        end
      end
    end

    protected

    # Request the next set in this sequence.
    # from and until attributes of resumption_token
    # are datetime limits
    # def next_set(token_string)
#       raise OAI::ResumptionTokenException.new unless @limit

#       token = ResumptionToken.parse(token_string)

#       @search = Search.new
#       @search.pqf_query = update_query_with(:all, token_conditions(token))
#       @result_set = @search.zoom_db.process_query(@search.pqf_query.to_s)

#       total = @result_set.size

#       if @limit < total
#         select_partial(token)
#       else # end of result set
#         @result_set.records
#       end
#     end

    # select a subset of the result set, and return it with a
    # resumption token to get the next subset
    # relies on @result_set being created in next_set
    # or find
#     def select_partial(token)
#       records = @result_set.records

#       raise OAI::ResumptionTokenException.new unless records

#       # this might not be right
#       # but the idea is to start with the next record
#       # after this finishes
#       offset = @result_set.size

#       PartialResult.new(records, token.next(offset))
#     end

    # build a sql conditions statement from the content
    # of a resumption token.  It is very important not to
    # miss any changes as records may change scope as the
    # harvest is in progress.  To avoid loosing any changes
    # the last 'id' of the previous set is used as the
    # filter to the next set.
#     def token_conditions(token)
#       last = token.last
#       sql = sql_conditions token.to_conditions_hash

#       return sql if 0 == last
#       # Now add last id constraint
#       sql[0] << " AND #{zoom_db.primary_key} > ?"
#       sql << last

#       return sql
#     end

    def update_query_with(selector, options = { })
      @search ||= Search.new

      # clear @search.pqf_query, so that we don't get previous query stuff
      @search.pqf_query = PqfQuery.new

      id_stub = ZoomDb.zoom_id_stub

      # if all or first add default query
      # to specify that be from this site
      # but exclude bootstrap data
      # otherwise we are looking for an exact record
      # i.e. the record id was passed in as the selector
      if selector.is_a?(Symbol) || !selector.to_s.include?(id_stub)
        # for right now, always limit this to local records
        @search.pqf_query.oai_identifier_include(id_stub, :operator => 'none')

        # add sorting as specified
        @search.pqf_query.sort_spec = options[:sort_spec]
        @search.update_sort_direction_value_for_pqf_query(options[:sort_direction]) if !options[:sort_direction].nil?

        # lookup set and add to query as appropriate
        @search.pqf_query.oai_setspec_include(options[:set]) if !options[:set].blank?

        # handle request date range
        if !options[:from].blank? || !options[:until].blank?
          # strftime("%Y-%m-%d %H:%M:%S")
          beginning = !options[:from].blank? ? options[:from].strftime("%Y-%m-%d %H:%M:%S%z") : nil
          ending = !options[:until].blank? ? options[:until].strftime("%Y-%m-%d %H:%M:%S%z") : nil

          # if earliest and latest records were added in the same second
          # from and until may match each other
          # and effectively no records match, so drop until
          ending = nil if beginning == ending

          @search.pqf_query.oai_datestamp_comparison(:beginning => beginning, :ending => ending, :operator => '@and')
        end

        # exclude bootstrap records, if no other criteria
        @search.pqf_query.oai_identifier_include('Bootstrap', :operator => '@not') if @search.pqf_query.operators.size == 0
      else
        @search.pqf_query.oai_identifier_include(selector, :operator => 'none', :should_be_exact => true)
      end
    end
  end
end
