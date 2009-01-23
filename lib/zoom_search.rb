module ZoomSearch
  unless included_modules.include? ZoomSearch
    def self.included(klass)
      klass.helper_method :count_items_for, :count_private_items_for, :find_related_items_for, :find_private_related_items_for
    end

    def count_items_for(zoom_class, options = {})
      options = { :dont_parse_results => true }.merge(options)

      make_search(zoom_class, options) do
        @search.pqf_query.kind_is(zoom_class, :operator => 'none')
        if @current_basket != @site_basket
          return Array.new unless permitted_to_view_private_items?
          @search.pqf_query.within(@current_basket.urlified_name)
        else
          @search.pqf_query.within(authorised_basket_names)
        end
      end
    end

    def count_private_items_for(zoom_class, options={})
      options = { :privacy => 'private' }.merge(options)
      count_items_for(zoom_class, options)
    end

    def find_related_items_for(item, zoom_class, options={})
      make_search(zoom_class, options) do
        @search.pqf_query.kind_is(zoom_class, :operator => 'none')
        @search.pqf_query.within(authorised_basket_names)
        @search.pqf_query.relations_include(url_for_dc_identifier(item), :should_be_exact => true)
        @search.add_sort_to_query_if_needed(:user_specified => 'last_modified', :direction => nil)
      end
    end

    def find_private_related_items_for(item, zoom_class, options={})
      options = { :privacy => 'private' }.merge(options)
      find_related_items_for(item, zoom_class, options)
    end

    private
    # get the urlified_names for baskets that we know the user has a right to see
    def authorised_basket_names
      @authorised_basket_names ||= @basket_access_hash.keys.collect { |key| key.to_s }
    end

    def make_search(zoom_class, options={})
      @privacy = (options[:privacy] == 'private') ? 'private' : 'public'
      @search = Search.new
      @search.zoom_db = ZoomDb.find_by_host_and_database_name('localhost', @privacy)
      @zoom_connection = @search.zoom_db.open_connection
      yield
      logger.debug("what is query: " + @search.pqf_query.to_s.inspect)
      @zoom_results = @search.zoom_db.process_query(:query => @search.pqf_query.to_s, :existing_connection => @zoom_connection)
      @search.pqf_query = PqfQuery.new

      if options[:dont_parse_results]
        @zoom_results
      else
        parse_results(@zoom_results, zoom_class, options)
      end
    end

    def parse_results(results, zoom_class, options={})
      options = { :result_set => results, :start_record => 0, :end_record => 5 }

      @results_verbose = Array.new
      if @zoom_results.size > 0
        still_image_results = Array.new
        raw_results = zoom_class.constantize.records_from_zoom_result_set( :result_set => options[:result_set],
                                                                           :start_record => options[:start_record],
                                                                           :end_record => options[:end_record])
        # create a hash of link, title, description for each record
        raw_results.each do |raw_record|
          result_from_xml_hash = parse_from_xml_oai_dc(raw_record)
          @results_verbose << result_from_xml_hash
          # we want to load local thumbnails for image results
          # we'll collect the still_image_ids as keys and then run one query below
          if result_from_xml_hash['locally_hosted'] && result_from_xml_hash['class'] == 'StillImage'
            still_image_results << result_from_xml_hash['id']
          end
        end
        if zoom_class == 'StillImage'
          StillImage.all(:conditions => ["id in (?)", still_image_results]).each do |image|
            @results_verbose.each do |result|
              if result['locally_hosted'] && result['id'].to_i == image.id
                result['still_image'] = image
              end
            end
          end
        end
      end
      @results = Array.new
      @results_verbose.each do |result|
        result_hash = { :title => result['title'], :url => result['url'] }
        result_hash[:still_image] = result['still_image'] if result['still_image']
        @results << result_hash
      end

      @results
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

        # description may sometimes be nil so if it is, skip this element so we don't get 500 errors
        next if field_value.nil?

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

  end
end
