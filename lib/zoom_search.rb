# A collection of methods, purpose of which has been derived from the code in search_controller.rb
# Performs queries to public/private zebra databases and returns results

module ZoomSearch
  unless included_modules.include? ZoomSearch

    # This gets added into application.rb so by making them helper methods here,
    # we can use them in our controllers and views throughout the site
    def self.included(klass)
      klass.helper_method :count_public_items_for, :count_private_items_for, :find_public_related_items_for, :find_private_related_items_for
    end

    # EOIN:
    # * stub methods out as we will be replacing search
    def count_public_items_for(zoom_class, options = {})
      0
    end
    def count_private_items_for(zoom_class, options={})
      0
    end
    def find_private_related_items_for(item, zoom_class, options={})
      {}
    end
    def find_public_related_items_for(item, zoom_class, options={})
      {}
    end

    # Performs a search and returns a Zoom Object (which you can run .size)
    # Since this is purely for the amount, we :dont_parse_results => true
    # which stops parse_results from running (saves time)
    # def count_public_items_for(zoom_class, options = {})
    #   options = { :dont_parse_results => true }.merge(options)
    #   make_search(zoom_class, options) {
    #     @search.pqf_query.kind_is(zoom_class, :operator => 'none')
    #   }[:total]
    # end

    # # Assigns privacy to 'private' and passes the same params through to count_public_items_for
    # def count_private_items_for(zoom_class, options={})
    #   options = { :privacy => 'private' }.merge(options)
    #   count_public_items_for(zoom_class, options)
    # end

    # # Performs a search of items related to an item, and returns an Array, filled with item hashes
    # # We add a sort query of last_modified though technically it should be by position
    # # in the acts_as_list setup, but that detail isn't stored in the zoom record at the moment
    # def find_public_related_items_for(item, zoom_class, options={})
    #   # searching related items, at least at this stage, is always site wide
    #   # but you can limit it by passing a basket object in
    #   options[:as_if_within_basket] = options[:as_if_within_basket].blank? ? @site_basket : options[:as_if_within_basket]
    #   make_search(zoom_class, options) do
    #     @search.pqf_query.kind_is(zoom_class, :operator => 'none')
    #     @search.pqf_query.relations_include(url_for_dc_identifier(item, { :force_http => true, :minimal => true }), :should_be_exact => true)
    #     @search.add_sort_to_query_if_needed(:user_specified => 'last_modified', :direction => nil)
    #   end
    # end

    # # Assigns privacy to 'private' and passes the same params through to find_private_related_items_for
    # def find_private_related_items_for(item, zoom_class, options={})
    #   options = { :privacy => 'private' }.merge(options)
    #   find_public_related_items_for(item, zoom_class, options)
    # end

    # private

    # # Each search is wrapped by this method. It instantiates a new search, opens a connection, yields
    # # any block it is passed (used to set other search query settings), scopes the search basket on
    # # current users location in the site, and authorization status, process's the query, resets tge query string
    # # and either returns the results right away, or passes the results to parse_results for parsing
    # def make_search(zoom_class, options={})
    #   @privacy = (options[:privacy] == 'private') ? 'private' : 'public'
    #   @search = Search.new
    #   @search.zoom_db = zoom_database
    #   @zoom_connection = @search.zoom_db.open_connection
    #   yield if block_given?
    #   # we usually want to scope to baskets the user has permission to
    #   # the only exception is when your are in find_related... which acts as if you are in site basket
    #   as_if_within_basket = options[:as_if_within_basket].nil? ? nil : options[:as_if_within_basket]
    #   return { :results => Array.new, :total => 0 } unless scoped_to_authorized_baskets(as_if_within_basket)

    #   @zoom_results = @search.zoom_db.process_query(query_options)

    #   @search.pqf_query = PqfQuery.new

    #   if options[:dont_parse_results]
    #     { :results => @zoom_results, :total => @zoom_results.size }
    #   else
    #     { :results => parse_results(@zoom_results, zoom_class, options), :total => @zoom_results.size }
    #   end
    # end

    # # Walter McGinnis, 2009-08-27
    # # right now Kete only needs abbreviated records back,
    # # but in the future, it might make sense to move this to @search attribute
    # # @search.element_set_name
    # def query_options
    #   { :query => @search.pqf_query.to_s,
    #     :existing_connection => @zoom_connection,
    #     :element_set_name => "oai-kete-short"}
    # end

    # # Filter results to only show in authorized baskets
    # # Site admins should be able to see everything (public and private) in any basket
    # # When searching in a non-site basket:
    # #    - dont return anything if the user doesn't have member (or greater) access in that basket
    # #    - scope the search to the current basket
    # # When searching in the site basket:
    # #    - return false if the users authorised_basket_names hash is blank (access to nothing)
    # #         (note: if we dont do this, we end up with invalid zebra queries)
    # #    - scope private searches to baskets the user has access to
    # # When user is logged out:
    # #    - dont return anything if making a private search
    # #    - scope the search to the current basket when in a non-site basket
    # def scoped_to_authorized_baskets(as_if_within_basket = nil)
    #   # this allows us to do site wide searches (or search basket from outside of it)
    #   basket = as_if_within_basket || @current_basket
    #   if logged_in?
    #     if basket != @site_basket
    #       return false if is_a_private_search? && !@site_admin && !authorised_basket_names.include?(basket.urlified_name)
    #       @search.pqf_query.within(basket.urlified_name)
    #     elsif is_a_private_search? # private search in the site basket
    #       return if authorised_basket_names.blank?
    #       @search.pqf_query.within(authorised_basket_names) unless @site_admin
    #     end
    #   else
    #     return false if is_a_private_search?
    #     if basket != @site_basket
    #       @search.pqf_query.within(basket.urlified_name)
    #     end
    #   end
    #   true
    # end

    # # Check if we are meant to be running a private search/query
    # def is_a_private_search?
    #   @privacy == "private"
    # end

    # # Fetch both databases in one go, they will be used later
    # def zoom_database
    #   @public_database ||= ZoomDb.find_by_database_name('public')
    #   @private_database ||= ZoomDb.find_by_database_name('private')
    #   return (is_a_private_search? ? @private_database : @public_database)
    # end

    # # Collect the urlified_names for baskets that we know the user has a right to see
    # def authorised_basket_names
    #   @authorised_basket_names ||= @basket_access_hash.keys.collect { |key| key.to_s }
    # end

    # # After a search is made, the results may be passed to this method. The ZoomResult object
    # # does little more than .size, so here we'll extract each the records found, and place each
    # # ones details into a hash, then append that hash to a results array (which will be usable)
    # # By default, we only parse the first five records. If you need more, overwrite :end_record
    # # in the options param.
    # def parse_results(results, zoom_class, options={})
    #   options = { :start_record => 0, :end_record => 5 }.merge(options)

    #   @results = Array.new
    #   if results.size > 0
    #     still_image_results = Array.new
    #     raw_results = results.records_from(options)
    #     raw_results.each do |raw_record|
    #       result_from_xml_hash = parse_from_xml_in(raw_record)
    #       @results << result_from_xml_hash
    #     end
    #   end
    #   @results
    # end

    # # grab the values we want from the zoom_record
    # # and return them as a hash
    # # zoom_record has been extended to be a nokogiri doc (http://nokogiri.rubyforge.org/nokogiri/)
    # # and contains a lot of convenience methods to grab parts of the record
    # # see vendor/plugins/acts_as_zoom/lib/record.rb
    # def parse_from_xml_in(zoom_record)
    #   # work through record and grab the values
    #   # there maybe multiples of the same element
    #   # we only want the first by convention
    #   result_hash = Hash.new

    #   # we should be able to deduce the class
    #   # whether the result is local
    #   # and the object's id from the oai_identifier
    #   oai_identifier = zoom_record.oai_identifier

    #   local_re = Regexp.new("^#{ZoomDb.zoom_id_stub}")
    #   class_id_re = Regexp.new("([^:]+):([0-9]+)$")

    #   class_id_match = oai_identifier.match class_id_re
    #   # index 0 is whole matching string
    #   result_hash[:class] = class_id_match[1]
    #   result_hash[:id] = class_id_match[2]

    #   if oai_identifier =~ local_re
    #     result_hash[:locally_hosted] = true
    #   else
    #     result_hash[:locally_hosted] = false
    #   end

    #   # make this nil by default
    #   # overwrite for local results with actual thumbnail object
    #   result_hash[:thumbnail] = nil
    #   result_hash[:media_content] = nil
    #   if ATTACHABLE_CLASSES.include?(result_hash[:class])
    #     thumbnail_xml = zoom_record.root.at(".//xmlns:thumbnail", zoom_record.root.namespaces)
    #     unless thumbnail_xml.blank?
    #       result_hash[:thumbnail] = thumbnail_xml.attributes.symbolize_keys
    #       result_hash[:thumbnail].each { |k, v| result_hash[:thumbnail][k] = v.value }
    #     end

    #     medium_xml = zoom_record.root.at(".//xmlns:medium", zoom_record.root.namespaces)
    #     unless medium_xml.blank?
    #       result_hash[:medium] = medium_xml.attributes.symbolize_keys
    #       result_hash[:medium].each { |k, v| result_hash[:medium][k] = v.value }
    #     end

    #     media_content_xml = zoom_record.root.at(".//xmlns:media_content", zoom_record.root.namespaces)
    #     unless media_content_xml.blank?
    #       result_hash[:media_content] = media_content_xml.attributes.symbolize_keys
    #       result_hash[:media_content].each { |k, v| result_hash[:media_content][k] = v.value }
    #     end
    #   end

    #   # get the oai_dc element
    #   # which we can use xpath to search
    #   # for all our standard dc element values
    #   oai_dc = zoom_record.to_oai_dc

    #   desired_fields = [['identifier', 'url'],
    #                     ['title'],
    #                     ['description', 'short_summary'],
    #                     ['date']]

    #   desired_fields.each do |field|
    #     # make xpath request to get first instance of the desired field's value
    #     # (dc elements may be used more than once)
    #     # we use a hardcoded xml path because oai_dc.namescapes doesn't return the one we need in Nokogiri 1.4.0 or later
    #     field_value = oai_dc_first_element_for(field[0], oai_dc)
    #     next if field_value.nil?
    #     field_value = field_value.content

    #     # description may sometimes be nil so if it is, skip this element so we don't get 500 errors
    #     next if field_value.nil?

    #     field_name = String.new
    #     if field[1].nil?
    #       field_name = field[0]
    #     else
    #       field_name = field[1]
    #     end

    #     # may want to truncate short_summary
    #     field_value = prepare_short_summary(field_value) if field_name == 'short_summary'

    #     result_hash[field_name.to_sym] = field_value
    #   end

    #   fields = oai_dc.xpath(".//dc:date", "xmlns:dc" => "http://purl.org/dc/elements/1.1/")
    #   result_hash[:dc_dates] = fields.collect { |f| f.content }

    #   # determine the topic type(s)
    #   topic_type_names = TopicType.all(:select => 'name').collect { |topic_type| topic_type.name }
    #   result_hash[:topic_types] = Array.new
    #   # we use a hardcoded xml path because oai_dc.namescapes doesn't return the one we need in Nokogiri 1.4.0 or later
    #   oai_dc.xpath(".//dc:coverage", "xmlns:dc" => "http://purl.org/dc/elements/1.1/").each do |node|
    #     value = node.content.strip
    #     result_hash[:topic_types] << value if topic_type_names.include?(value)
    #   end

    #   # get coverage values, these can be used for geographic values or temporal information
    #   # we use a hardcoded xml path because oai_dc.namescapes doesn't return the one we need in Nokogiri 1.4.0 or later
    #   location_or_temporal_nodes = oai_dc.xpath(".//dc:coverage", "xmlns:dc" => "http://purl.org/dc/elements/1.1/").select { |node| !node.content.scan(":").blank? }

    #   # we only want values that have latitude and longitude specified
    #   location_arrays = location_or_temporal_nodes.collect do |node|
    #     values = node.content.split(":").reject { |i| i.blank? }

    #     values_test = values.select { |v| v.present? && v.include?(',') && v.split(',').size == 2 }
    #     if values_test.blank?
    #       values = Array.new
    #     end
    #     values
    #   end.reject { |array| array.empty?}

    #   # transform location arrays to an array of hashes
    #   # we have two possible formats for location info:
    #   # [address string, zoom_level, no_map, latlng string]
    #   # or
    #   # [zoom_level, latlng string, no_map]
    #   # no map, by the time it gets to search results should always be 0 (false)
    #   # we can drop it from location_hash
    #   array_of_location_hashes = Array.new
    #   location_arrays.each do |location_array|
    #     location_hash = Hash.new
    #     last_value = location_array.last
    #     coords = Array.new

    #     if last_value.is_a?(String) &&
    #         last_value.include?(',') &&
    #         last_value.split(',').size == 2
    #       coords = last_value
    #       location_hash = { :address => location_array[0],
    #         :zoom_level => location_array[1] }
    #     else
    #       coords = location_array[1]
    #       location_hash = { :address => nil,
    #         :zoom_level => location_array[0]
    #       }
    #     end

    #     # assign coordinates, change coordinates to fixnums
    #     coords = coords.split(',')
    #     location_hash[:latitude] = coords[0].to_f
    #     location_hash[:longitude] = coords[1].to_f
    #     location_hash[:latlng] = coords.join(',')

    #     array_of_location_hashes << location_hash
    #   end
    #   # we need the lat/lngs when we initialize the map
    #   # separate from results_hash
    #   # this covers all locations for a give set of results
    #   @coordinates_for_results ||= Array.new

    #   # this is the set of location JUST FOR THIS RESULT
    #   result_hash[:associated_locations] = Array.new

    #   # add our locations to appropriate instance variables
    #   array_of_location_hashes.each do |l|
    #     @coordinates_for_results << l[:latlng].split(',')

    #     result_hash[:associated_locations] << l
    #     @number_of_locations_count = @number_of_locations_count.blank? ? 1 : @number_of_locations_count + 1
    #   end

    #   related_items = zoom_record.root.at(".//xmlns:related_items", zoom_record.root.namespaces)
    #   unless related_items.blank?
    #     result_hash[:related] = Hash.new
    #     result_hash[:related][:counts] = Hash.new
    #     # we have to use the .value to retrieve the actual value, otherwise it is returned as a Nokogiri::XML:Attr object
    #     related_items.attributes.each { |k, v| result_hash[:related][:counts][k.to_sym] = v.value }
    #     result_hash[:related][:still_images] = Hash.new
    #     zoom_record.root.xpath(".//xmlns:still_image", zoom_record.root.namespaces).each do |image_xml|
    #       image_attributes = Hash.new
    #       image_xml.attributes.each { |k, v| image_attributes[k.to_sym] = v.value }
    #       key = image_attributes[:relation_order]
    #       image_attributes.delete(:relation_order)
    #       result_hash[:related][:still_images][key] = image_attributes
    #       result_hash[:related][:still_images][key][:thumbnail] = Hash.new
    #       image_xml.at(".//xmlns:thumbnail", zoom_record.root.namespaces).attributes.each do |k, v|
    #         result_hash[:related][:still_images][key][:thumbnail][k.to_sym] = v.value
    #       end
    #     end
    #   end

    #   return result_hash
    # end

    # # Time.parse doesn't support only a year, or only a year and month
    # # So we need to fill in these with 01 (beginning) values ourselves
    # # Then convert to UTC because this is what Zebra stores
    # def parse_date_into_zoom_compatible_format(value, look_from = :beginning)
    #   value = value.strip
    #   if value =~ /^(\d{4})-?(\d{1,2})?$/
    #     default_month = look_from == :beginning ? 01 : 12
    #     default_day = look_from == :beginning ? 01 : 31
    #     time = Time.zone.parse("#{$1}-#{$2 || default_month}-#{$3 || default_day}")
    #   else
    #     time = Time.zone.parse(value)
    #   end
    #   # all times in zebra are stored as UTC, so compare against that for better results
    #   time.utc.strftime("%Y-%m-%d")
    # rescue ArgumentError
    #   nil
    # end

    # def oai_dc_first_element_for(field_name, oai_dc)
    #   oai_dc.xpath(".//dc:#{field_name}", "xmlns:dc" => "http://purl.org/dc/elements/1.1/").first
    # end
  end
end
