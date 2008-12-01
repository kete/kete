module GoogleMap

  module Mapper
    unless included_modules.include? GoogleMap::Mapper
      def self.included(klass)
        case klass.name
        when 'BasketsController'
          klass.send :before_filter, :prepare_google_map_without_instantiation, :only => ['choose_type']
        when 'IndexPageController'
          klass.send :before_filter, :prepare_google_map, :only => ['index']
        else
          klass.send :before_filter, :prepare_google_map, :only => ['show', 'new', 'create', 'edit', 'update']
        end
        klass.helper GoogleMap::ViewHelpers
      end

      private

      def prepare_google_map_without_instantiation
        # turn it on here because we dont rerender the application template when we load a form via AJAX
        # so if the JS isn't already there on loading, then we run into errors
        @using_google_maps = true

        # the basket ajax item adder doesn't need the code run when the page is loaded,
        # only later when the form is generated, so set it not to do this
        @do_not_load_google_maps_on_page_load = true
      end

      def prepare_google_map
        # just because the module was include doesn't mean this page has map extended fields. we'll set this true later
        # (in the extended_field_map_editor method below) when looping over the fields that call the method
        @using_google_maps = false

        # we dont want the local search field o draggable markers on the index page or item show page, only new/edit pages
        @google_map_on_index_or_show_page = true if ['index', 'show'].include?(params[:action])
      end
    end
  end

  module ExtendedFieldsHelper
    def extended_field_map_editor(name, value, options = {}, show_text_fields = true)
      # Google maps are disabled by default, so make sure we enable them here
      # This method is called on all pages
      @using_google_maps = true

      map_options = { :style => 'width:550px; height:380px;' }
      map_options.merge!(options)

      # we fill the text field values in one of three ways
      # first, if the new/edit form has been submitted, we use those values
      # second, if we're editing but not submitted yet, we use the items values
      # lastly, if it's a brand new item (no values, not submitted form), we pull default coords from yml config

      @current_coords = ''
      @current_zoom_lvl = ''
      if !param_from_field_name(name).blank?
        @current_coords = param_from_field_name(name)[:coords]
        @current_zoom_lvl = param_from_field_name(name)[:zoom_lvl]
      elsif !value.blank?
        @current_coords = value[1]
        @current_zoom_lvl = value[0]
      end

      safe_name = name.gsub('[', '_').gsub(']', '')
      map_data = { :map_id => "#{safe_name}_map_div",
                   :latitude => @current_coords.split(',')[0],
                   :longitude => @current_coords.split(',')[1],
                   :zoom_lvl => @current_zoom_lvl,
                   :coords_field => "#{safe_name}_map_coords_value",
                   :zoom_lvl_field => "#{safe_name}_map_zoom_value" }
      # an array of maps to be displayed on this page
      @google_maps_list ||= Array.new             
      @google_maps_list << map_data

      html = content_tag('div', nil, map_options.merge({ :id => map_data[:map_id] }))
      if show_text_fields
        html += text_field_tag("#{name}[coords]",
                               @current_coords,
                               { :id => map_data[:coords_field],
                                 :readonly => 'readonly' })
        html += text_field_tag("#{name}[zoom_lvl]",
                               @current_zoom_lvl,
                               { :id => map_data[:zoom_lvl_field],
                                 :readonly => 'readonly',
                                 :size => '2' })
      end
      html
    end

    private

    def param_from_field_name(field_name)
      parts = ''
      field_name.gsub(/\[/, " ").gsub(/\]/, "").split(" ").each { |part| parts += "[:#{part}]" }
      begin
        eval("params#{parts}")
      rescue
        ''
      end
    end
  end

  module ExtendedContent
    def validate_extended_map_field_content(extended_field_mapping, values)
      # Allow nil values. If this is required, the nil value will be caught earlier.
      return nil if values.blank?
      unless values.is_a?(Array)
        "is not an array of latitude and longitude. Why?"
      end
      # we should also check here that [0] is the zoom and [1] is the coords
      # and if they arn't reverse them (since we assume that order later in the code)
    end
  end

  module ViewHelpers
    def google_map_initializers
      unless @google_maps_list.blank?
        @google_maps_initializers = String.new
        @google_maps_list.each do |google_map|
          @google_maps_initializers += "initialize_google_map("
          @google_maps_initializers += "'#{google_map[:map_id]}'"
          @google_maps_initializers += (google_map[:latitude].blank? ? ", ''" : ", #{google_map[:latitude]}")
          @google_maps_initializers += (google_map[:longitude].blank? ? ", ''" : ", #{google_map[:longitude]}")
          @google_maps_initializers += (google_map[:zoom_lvl].blank? ? ", ''" : ", #{google_map[:zoom_lvl]}")
          @google_maps_initializers += ", '#{google_map[:coords_field]}'"
          @google_maps_initializers += ", '#{google_map[:zoom_lvl_field]}'"
          @google_maps_initializers += ");\n"
        end
        @google_maps_initializers
      else
        ''
      end
    end

    def load_google_map_api
      if @using_google_maps
        # Google maps cannot run without a configuration so make sure, if they're using Google Maps, that they configure it.
        @gma_config_path = File.join(RAILS_ROOT, 'config/google_map_api.yml')
        raise "Error: Trying to use Google Maps without configuation (config/google_map_api.yml)." unless File.exists?(@gma_config_path)
        @gma_config = YAML.load(IO.read(@gma_config_path))

        # Prepare the Google Maps needing to load
        @google_maps_initializers = google_map_initializers

        unless @gma_config[:google_map_api][:default_latitude].blank? || @gma_config[:google_map_api][:default_longitude].blank?
          @default_latitude = @gma_config[:google_map_api][:default_latitude]
          @default_longitude = @gma_config[:google_map_api][:default_longitude]
        end
        unless @gma_config[:google_map_api][:default_zoom_lvl].blank?
          @default_zoom_lvl = @gma_config[:google_map_api][:default_zoom_lvl]
        end

        # This works, but rails tries to add a .js on the end, which invalidated the api key, so we add the format= to hackishly fix this
        html = javascript_include_tag("http://www.google.com/jsapi?key=#{@gma_config[:google_map_api][:api_key]}&amp;format=") + "\n"
        html += javascript_tag("
          // this initiates the Google Map API (version 2)
          google.load('maps', '2', {'other_params':'sensor=true'});
          // the function run when the page finishes loading, to initiate the google map
          function initialize_google_map(map_id, latitude, longitude, zoom_lvl, latlng_text_field, zoom_text_field) {
            // make sure we don't do any google map code unless the browser supports it
            if (!google.maps.BrowserIsCompatible()) {
              alert('Google Maps is not compatible with this browser. Try using Firefox 3, Internet Explorer 7, or Safari 3.'); return;
            }
            // check the google map div is present on the page before continuing
            if (!$(map_id)) {
              alert('You are trying to initiate the google map api on a non-existant div (' + map_id + '). Debug this!'); return;
            }
            // initialize the google map
            var map = new google.maps.Map2($(map_id));
            // store the latlng/zoom text field id's on the map object for use later
            map.latlng_text_field = latlng_text_field
            map.zoom_text_field = zoom_text_field
            // If these values are blank, make one last attempt to add values to them
            if (latitude == '') {
              if (google.loader.ClientLocation.latitude) { latitude = google.loader.ClientLocation.latitude; }
              else { latitude = #{@default_latitude}; }
            }
            if (longitude == '') {
              if (google.loader.ClientLocation.longitude) { longitude = google.loader.ClientLocation.longitude; }
              else { longitude = #{@default_longitude}; }
            }
            if (zoom_lvl == '') { zoom_lvl = #{@default_zoom_lvl}; }
            // If the values arn't populated by now, something went wrong.
            if (latitude == '' || longitude == '' || zoom_lvl == '') {
              alert('ERROR: One of latitude, longitude, or zoom level has not been set. Debug this!'); return;
            }
            if ($(map.latlng_text_field).value == '') { $(map.latlng_text_field).value = latitude + ',' + longitude; }
            if ($(map.zoom_text_field).value == '') { $(map.zoom_text_field).value = zoom_lvl; }
            // center the map on the default latitude, longitude and zoom level
            // (comes from either params, the item being edited, or config)
            map.setCenter(new google.maps.LatLng(latitude, longitude), zoom_lvl);
            // add the small controls in the top left of the map (for moving and zooming)
            map.addControl(new google.maps.SmallMapControl());
            // if we are on the show page, dont show search controls, dont make markers draggable
            // else if we are on the new/edit pages, bind a search control to the map
            #{@google_map_on_index_or_show_page ? 'remove_all_markers_and_add_one_to(map, latitude, longitude, false);' :
                                                  'map.addControl(new google.maps.LocalSearch({suppressInitialResultSelection : true}),
                                                   new GControlPosition(G_ANCHOR_BOTTOM_RIGHT, new GSize(10,25)));
                                                   remove_all_markers_and_add_one_to(map, latitude, longitude, true);'}
            // the code from this point only executes on new/edit pages, not the show pages
            if ($(map.latlng_text_field) && $(map.zoom_text_field)) {
              // when a user clicks the map, add a marker and update the coords and zoom level
              google.maps.Event.addListener(map, 'click', function(overlay, latlng) {
                // make sure that a latitude and longitude is passed in
                if (latlng) {
                  // remove all existing markers and add one where the user clicked
                  remove_all_markers_and_add_one_to(map, latlng.y, latlng.x, true);
                  // toUrlValue(6) gives us a string like   -45.861836,127.398373  (which is the format we want)
                  $(map.latlng_text_field).value = latlng.toUrlValue(6);
                  // the current maps zoom level
                  $(map.zoom_text_field).value = map.getZoom();
                }
              });
              // when a user stops dragging/zooming, update the zoom level (not the coords, thats what the pinpoint is for)
              google.maps.Event.addListener(map, 'moveend', function() {
                $(map.zoom_text_field).value = map.getZoom();
              });
            }
          }

          // remove all existing markers and one at specified latitude and longitude
          function remove_all_markers_and_add_one_to(map, latitude, longitude, draggable) {
            // clears all overlays (info boxes, markers etc)
            map.clearOverlays();
            // create the marker (draggable is passed in as either true or false)
            map.current_marker = new GMarker(new GLatLng(latitude, longitude), {draggable: draggable});
            // add the marker to the map
            map.addOverlay(map.current_marker);
            // when a user stops dragging the marker, update the coords and zoom level
            google.maps.Event.addListener(map.current_marker, 'dragend', function() {
              // toUrlValue(6) gives us a string like   -45.861836,127.398373  (which is the format we want)
              $(map.latlng_text_field).value = map.current_marker.getLatLng().toUrlValue(6);
              // the current maps zoom level
              $(map.zoom_text_field).value = map.getZoom();
            });
          }

          #{'// when the page has finished loading, then initiate the google map
            document.observe(\'dom:loaded\', function() { ' + @google_maps_initializers + ' });' unless @do_not_load_google_maps_on_page_load}
        ") + "\n"
        html += javascript_include_tag("http://www.google.com/uds/api?file=uds.js&amp;v=1.0&amp;key=#{@gma_config[:google_map_api][:api_key]}") + "\n"
        html += javascript_include_tag("http://www.google.com/uds/solutions/localsearch/gmlocalsearch") + "\n"
        html += stylesheet_link_tag("http://www.google.com/uds/css/gsearch.css") + "\n"
        html += stylesheet_link_tag("http://www.google.com/uds/solutions/localsearch/gmlocalsearch.css") + "\n"
        html
      end
    end
  end

end