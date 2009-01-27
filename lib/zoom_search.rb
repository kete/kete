# A collection of methods, purpose of which has been derived from the code in search_controller.rb
# Performs queries to public/private zebra databases and returns results

module ZoomSearch
  unless included_modules.include? ZoomSearch

    # This gets added into application.rb so by making them helper methods here,
    # we can use them in our controllers and views throughout the site
    def self.included(klass)
      klass.helper_method :count_items_for, :count_private_items_for, :find_related_items_for, :find_private_related_items_for
    end

    # Performs a search and returns a Zoom Object (which you can run .size)
    # Since this is purely for the amount, we :dont_parse_results => true
    # which stops parse_results from running (saves time)
    def count_items_for(zoom_class, options = {})
      options = { :dont_parse_results => true }.merge(options)
      make_search(zoom_class, options) do
        @search.pqf_query.kind_is(zoom_class, :operator => 'none')
      end
    end

    # Assigns privacy to 'private' and passes the same params through to count_items_for
    def count_private_items_for(zoom_class, options={})
      options = { :privacy => 'private' }.merge(options)
      count_items_for(zoom_class, options)
    end

    # Performs a search of items related to an item, and returns an Array, filled with item hashes
    # We add a sort query of last_modified though technically it should be by position
    # in the acts_as_list setup, but that detail isn't stored in the zoom record at the moment
    def find_related_items_for(item, zoom_class, options={})
      make_search(zoom_class, options) do
        @search.pqf_query.kind_is(zoom_class, :operator => 'none')
        @search.pqf_query.relations_include(url_for_dc_identifier(item), :should_be_exact => true)
        @search.add_sort_to_query_if_needed(:user_specified => 'last_modified', :direction => nil)
      end
    end

    # Assigns privacy to 'private' and passes the same params through to find_related_items_for
    def find_private_related_items_for(item, zoom_class, options={})
      options = { :privacy => 'private' }.merge(options)
      find_related_items_for(item, zoom_class, options)
    end

    private

    # Each search is wrapped by this method. It instantiates a new search, opens a connection, yields
    # any block it is passed (used to set other search query settings), scopes the search basket on
    # current users location in the site, and authorization status, process's the query, resets tge query string
    # and either returns the results right away, or passes the results to parse_results for parsing
    def make_search(zoom_class, options={})
      @privacy = (options[:privacy] == 'private') ? 'private' : 'public'
      @search = Search.new
      @search.zoom_db = zoom_database
      @zoom_connection = @search.zoom_db.open_connection
      yield if block_given?
      return Array.new unless scoped_to_authorized_baskets # we'll likely always want to scope to baskets the user has permission to
      logger.debug("what is query: " + @search.pqf_query.to_s.inspect)
      @zoom_results = @search.zoom_db.process_query(:query => @search.pqf_query.to_s, :existing_connection => @zoom_connection)
      @search.pqf_query = PqfQuery.new

      if options[:dont_parse_results]
        @zoom_results
      else
        parse_results(@zoom_results, zoom_class, options)
      end
    end

    # Filter results to only show in authorized baskets
    # Site admins should be able to see everything (public and private) in any basket
    # When searching in a non-site basket:
    #    - dont return anything if the user doesn't have member (or greater) access in that basket
    #    - scope the search to the current basket
    # When searching in the site basket:
    #    - return false if the users authorised_basket_names hash is blank (access to nothing)
    #         (note: if we dont do this, we end up with invalid zebra queries)
    #    - scope private searches to baskets the user has access to
    # When user is logged out:
    #    - dont return anything if making a private search
    #    - scope the search to the current basket when in a non-site basket
    def scoped_to_authorized_baskets
      if logged_in?
        if @current_basket != @site_basket
          return false if is_a_private_search? && !@site_admin && !authorised_basket_names.include?(@current_basket.urlified_name)
          @search.pqf_query.within(@current_basket.urlified_name)
        elsif is_a_private_search? # private search in the site basket
          return if authorised_basket_names.blank?
          @search.pqf_query.within(authorised_basket_names) unless @site_admin
        end
      else
        return false if is_a_private_search?
        if @current_basket != @site_basket
          @search.pqf_query.within(@current_basket.urlified_name)
        end
      end
      true
    end

    # Check if we are meant to be running a private search/query
    def is_a_private_search?
      @privacy == "private"
    end

    # Fetch both databases in one go, they will be used later
    def zoom_database
      @public_database ||= ZoomDb.find_by_host_and_database_name('localhost', 'public')
      @private_database ||= ZoomDb.find_by_host_and_database_name('localhost', 'private')
      return (is_a_private_search? ? @private_database : @public_database)
    end

    # Collect the urlified_names for baskets that we know the user has a right to see
    def authorised_basket_names
      @authorised_basket_names ||= @basket_access_hash.keys.collect { |key| key.to_s }
    end

    # After a search is made, the results may be passed to this method. The ZoomResult object
    # does little more than .size, so here we'll extract each the records found, and place each
    # ones details into a hash, then append that hash to a results array (which will be usable)
    # By default, we only parse the first five records. If you need more, overwrite :end_record
    # in the options param.
    def parse_results(results, zoom_class, options={})
      options = { :result_set => results, :start_record => 0, :end_record => 5 }.merge(options)

      @results = Array.new
      if results.size > 0
        still_image_results = Array.new
        raw_results = zoom_class.constantize.records_from_zoom_result_set(options)
        raw_results.each do |raw_record|
          result_from_xml_hash = parse_from_xml_in(raw_record)
          @results << result_from_xml_hash
        end
      end
      @results
    end

    # grab the values we want from the zoom_record
    # and return them as a hash
    # zoom_record has been extended to be a nokogiri doc (http://nokogiri.rubyforge.org/nokogiri/)
    # and contains a lot of convenience methods to grab parts of the record
    # see vendor/plugins/acts_as_zoom/lib/record.rb
    def parse_from_xml_in(zoom_record)
      # work through record and grab the values
      # there maybe multiples of the same element
      # we only want the first by convention
      result_hash = Hash.new

      # we should be able to deduce the class
      # whether the result is local
      # and the object's id from the oai_identifier
      oai_identifier = zoom_record.oai_identifier

      local_re = Regexp.new("^#{ZoomDb.zoom_id_stub}")
      class_id_re = Regexp.new("([^:]+):([0-9]+)$")

      class_id_match = oai_identifier.match class_id_re
      # index 0 is whole matching string
      result_hash[:class] = class_id_match[1]
      result_hash[:id] = class_id_match[2]

      if oai_identifier =~ local_re
        result_hash[:locally_hosted] = true
      else
        result_hash[:locally_hosted] = false
      end

      # make this nil by default
      # overwrite for local results with actual thumbnail object
      result_hash[:thumbnail] = nil
      result_hash[:media_content] = nil
      if ATTACHABLE_CLASSES.include?(result_hash[:class])
        thumbnail_xml = zoom_record.root.at(".//xmlns:thumbnail", zoom_record.root.namespaces)
        unless thumbnail_xml.blank?
          result_hash[:thumbnail] = thumbnail_xml.attributes.symbolize_keys
          result_hash[:thumbnail].each { |k, v| result_hash[:thumbnail][k] = v.value }
        end

        media_content_xml = zoom_record.root.at(".//xmlns:media_content", zoom_record.root.namespaces)
        unless media_content_xml.blank?
          result_hash[:media_content] = media_content_xml.attributes.symbolize_keys
          result_hash[:media_content].each { |k, v| result_hash[:media_content][k] = v.value }
        end
      end

      # get the oai_dc element
      # which we can use xpath to search
      # for all our standard dc element values
      oai_dc = zoom_record.to_oai_dc

      desired_fields = [['identifier', 'url'],
                        ['title'],
                        ['description', 'short_summary'],
                        ['date']]

      desired_fields.each do |field|
        # make xpath request to get first instance of the desired field's value
        # (dc elements may be used more than once)
        field_value = oai_dc.xpath(".//dc:#{field[0]}", oai_dc.namespaces).first.content

        # description may sometimes be nil so if it is, skip this element so we don't get 500 errors
        next if field_value.nil?

        field_name = String.new
        if field[1].nil?
          field_name = field[0]
        else
          field_name = field[1]
        end

        # may want to truncate short_summary
        field_value = prepare_short_summary(field_value) if field_name == 'short_summary'

        result_hash[field_name.to_sym] = field_value
      end

      related_items = zoom_record.root.at(".//xmlns:related_items", zoom_record.root.namespaces)
      unless related_items.blank?
        result_hash[:related] = Hash.new
        result_hash[:related][:counts] = Hash.new
        # we have to use the .value to retrieve the actual value, otherwise it is returned as a Nokogiri::XML:Attr object
        related_items.attributes.each { |k, v| result_hash[:related][:counts][k.to_sym] = v.value }
        result_hash[:related][:still_images] = Hash.new
        zoom_record.root.xpath(".//xmlns:still_image", zoom_record.root.namespaces).each do |image_xml|
          image_attributes = Hash.new
          image_xml.attributes.each { |k, v| image_attributes[k.to_sym] = v.value }
          key = image_attributes[:relation_order]
          image_attributes.delete(:relation_order)
          result_hash[:related][:still_images][key] = image_attributes
          result_hash[:related][:still_images][key][:thumbnail] = Hash.new
          image_xml.at(".//xmlns:thumbnail", zoom_record.root.namespaces).attributes.each do |k, v|
            result_hash[:related][:still_images][key][:thumbnail][k.to_sym] = v.value
          end
        end
      end

      logger.debug("what is result_hash: " + result_hash.inspect)

      return result_hash
    end

  end
end
