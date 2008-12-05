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
    def extended_field_map_editor(name, value, options = {}, generate_text_fields = true, display_address = false)
      # Google maps are disabled by default, so make sure we enable them here
      # This method is called on all pages
      @using_google_maps = true

      map_options = { :style => 'width:550px; height:380px;' }
      map_options.merge!(options)

      # we fill the text field values in one of two ways
      # first, if the new/edit form has been submitted, we use those values
      # second, if we're editing but not submitted yet, we use the items values
      # if they still don't exist by now, we'll determine them in JS later

      @current_coords = ''
      @current_zoom_lvl = ''
      @current_address = ''
      if !param_from_field_name(name).blank?
        # these values are coming from a submitted new/edit form
        @current_coords = param_from_field_name(name)[:coords]
        @current_zoom_lvl = param_from_field_name(name)[:zoom_lvl]
        @current_address = param_from_field_name(name)[:address]
      elsif !value.blank?
        # these values are coming from an edited item
        @current_coords = value[1]
        @current_zoom_lvl = value[0]
        @current_address = value[2]
      end

      # create a safe name (letters and underscores only) from the field name
      safe_name = name.gsub('[', '_').gsub(']', '')

      # populate a map data hash with details for this map (can have multiple maps on each item)
      map_data = { :map_id => "#{safe_name}_map_div",
                   :latitude => @current_coords.split(',')[0],
                   :longitude => @current_coords.split(',')[1],
                   :zoom_lvl => @current_zoom_lvl,
                   :address => @current_address,
                   :coords_field => "#{safe_name}_map_coords_value",
                   :zoom_lvl_field => "#{safe_name}_map_zoom_value",
                   :address_field => "#{safe_name}_map_address" }
      # an array of maps to be displayed on this page
      @google_maps_list ||= Array.new
      @google_maps_list << map_data

      # create the google map div
      html = content_tag('div', nil, map_options.merge({ :id => map_data[:map_id] }))
      if generate_text_fields
        # if we're on the edit pages, we want these fields to be present
        html += text_field_tag("#{name}[coords]",
                               @current_coords,
                               { :id => map_data[:coords_field],
                                 :readonly => 'readonly',
                                 :style => 'display:none;' })
        html += text_field_tag("#{name}[zoom_lvl]",
                               @current_zoom_lvl,
                               { :id => map_data[:zoom_lvl_field],
                                 :readonly => 'readonly',
                                 :size => '2',
                                  :style => 'display:none;' })
        html += "<br />" + text_field_tag("#{name}[address]",
                               @current_address,
                               { :id => map_data[:address_field],
                                 :readonly => 'readonly',
                                 :size => '45',
                                  :style => 'display:none;' })
      end
      # If we're on the show pages, and the map type shows the address
      # append a paragraph after the google map with the address value
      html += content_tag('p', @current_address) if display_address
      html
    end
    # both the google map and google map with address options use the same code
    alias extended_field_map_address_editor extended_field_map_editor

    private

    # when we are passed in a field name, we need to convert it to a param evaluation
    def param_from_field_name(field_name)
      parts = ''
      field_name.gsub(/\[/, " ").gsub(/\]/, "").split(" ").each { |part| parts += "[:#{part}]" }
      begin
        # evaluate the field
        eval("params#{parts}")
      rescue
        # just in case the above doesn't work, return an empty string so it doesn't error out
        ''
      end
    end
  end

  module ExtendedContent
    def validate_extended_map_field_content(extended_field_mapping, values)
      # Allow nil values. If this is required, the nil value will be caught earlier.
      return nil if values.blank?
      # the values passed in should form an array
      unless values.is_a?(Array)
        "is not an array of latitude and longitude. Why?"
      end
      # TODO: we should also check here that [0] is the zoom, [1] is the coords, and [2] is the address
      # and if they arn't reverse them (since we assume that order later in the code)
    end
    # both the google map and google map with address options use the same code
    alias validate_extended_map_address_field_content validate_extended_map_field_content
  end

  module ViewHelpers
    # We use this to generate the javascript to initialize each Google Map instance
    def google_map_initializers
      # Are there any google maps to initialize on this page?
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
          @google_maps_initializers += ", '#{google_map[:address_field]}'"
          @google_maps_initializers += ");\n"
        end
        @google_maps_initializers
      else
        ''
      end
    end

    def load_google_map_api
      # Only if we are using Google Maps on this page
      # By default, the variable @using_google_maps is false (except on the Add Item AJAX forms)
      # It is set to true when rendering the extended fields so we don't unnessesarily load the JS
      # when no fields on the page actually need it
      if @using_google_maps
        # Google maps cannot run without a configuration so make sure, if they're using Google Maps, that they configure it.
        @gma_config_path = File.join(RAILS_ROOT, 'config/google_map_api.yml')
        raise "Error: Trying to use Google Maps without configuation (config/google_map_api.yml)." unless File.exists?(@gma_config_path)
        @gma_config = YAML.load(IO.read(@gma_config_path))

        # Prepare the Google Maps needing to load
        @google_maps_initializers = google_map_initializers

        # Get the default latitude, longitude, and zoom level just in case we need them later
        unless @gma_config[:google_map_api][:default_latitude].blank? || @gma_config[:google_map_api][:default_longitude].blank?
          @default_latitude = @gma_config[:google_map_api][:default_latitude]
          @default_longitude = @gma_config[:google_map_api][:default_longitude]
        end
        unless @gma_config[:google_map_api][:default_zoom_lvl].blank?
          @default_zoom_lvl = @gma_config[:google_map_api][:default_zoom_lvl]
        end

        # This works, but rails tries to add a .js on the end, which invalidated the api key, so we add the format= to hackishly fix this
        html = javascript_include_tag("http://www.google.com/jsapi?key=#{@gma_config[:google_map_api][:api_key]}&amp;format=") + "\n"
        # This is where the real action happens. It's confusing so I've commented as much as possible.
        html += javascript_tag("
          // this initiates the Google Map API (version 2)
          google.load('maps', '2', {'other_params':'sensor=true'});

          // the function run when the page finishes loading, to initiate the google map
          function initialize_google_map(map_id, latitude, longitude, zoom_lvl, latlng_text_field, zoom_text_field, address_text_field) {
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
            // store the several objects/values in the map object for easy access
            // it also makes it possible to have different maps on the same page
            map.geocoder_obj = new google.maps.ClientGeocoder();
            map.latitude_value = latitude
            map.longitude_value = longitude
            map.zoom_lvl_value = zoom_lvl
            map.latlng_text_field = latlng_text_field
            map.zoom_text_field = zoom_text_field
            map.address_text_field = address_text_field
            // Make sure we have the nessesary fields present
            if (!verify_all_fields_present(map)) { return; }
            // center the map on the default latitude, longitude and zoom level
            // (comes from either params, the item being edited, or config)
            map.setCenter(new google.maps.LatLng(map.latitude_value, map.longitude_value), map.zoom_lvl_value);
            // add the small controls in the top left of the map (for moving and zooming)
            map.addControl(new google.maps.SmallMapControl());
            // if we are on the index/show page, dont show search controls, dont make markers draggable
            // else if we are on the new/edit pages, bind a search control to the map, and allow dragging
            #{@google_map_on_index_or_show_page ? 'remove_all_markers_and_add_one_to(map, map.latitude_value, map.longitude_value, false);' :
                                                  'map.addControl(new google.maps.LocalSearch({suppressInitialResultSelection : true}),
                                                   new GControlPosition(G_ANCHOR_BOTTOM_RIGHT, new GSize(10,25)));
                                                   remove_all_markers_and_add_one_to(map, map.latitude_value, map.longitude_value, true);'}
            // the code from this point only executes on new/edit pages, not the show pages
            if ($(map.latlng_text_field) && $(map.zoom_text_field) && $(map.address_text_field)) {
              // when a user clicks the map, add a marker and update the coords and zoom level
              google.maps.Event.addListener(map, 'click', function(overlay, latlng) {
                // make sure that a latitude and longitude is passed in
                if (latlng) {
                  // update the map data field
                  update_map_data(map, latlng);
                }
              });
              // when a user stops dragging/zooming, update the zoom level (not the coords, thats what the pinpoint is for)
              google.maps.Event.addListener(map, 'moveend', function() {
                $(map.zoom_text_field).value = map.getZoom();
              });
            }
          }

          // make sure the fields are filled in, and error out if they arn't at the end
          function verify_all_fields_present(map) {
            // If these values are blank, make one last attempt to add values to them
            // Do this by first seeing if we can get the users location, and if not
            // Use the default lat/lng/zoom in the kete's google api config file
            if (map.latitude_value == '') {
              if (google.loader.ClientLocation.latitude) { map.latitude_value = google.loader.ClientLocation.latitude; }
              else { map.latitude_value = #{@default_latitude}; }
            }
            if (map.longitude_value == '') {
              if (google.loader.ClientLocation.longitude) { map.longitude_value = google.loader.ClientLocation.longitude; }
              else { map.longitude_value = #{@default_longitude}; }
            }
            if (map.zoom_lvl_value == '') { map.zoom_lvl_value = #{@default_zoom_lvl}; }
            // If the values arn't populated by now (after 4 different sources), something went wrong.
            if (map.latitude_value == '' || map.longitude_value == '' || map.zoom_lvl_value == '') {
              alert('ERROR: One of latitude, longitude, or zoom level has not been set. Debug this!'); return false;
            }
            if ($(map.latlng_text_field) && $(map.latlng_text_field).value == '') {
              $(map.latlng_text_field).value = map.latitude_value + ',' + map.longitude_value;
            }
            if ($(map.zoom_text_field) && $(map.zoom_text_field).value == '') {
              $(map.zoom_text_field).value = map.zoom_lvl_value;
            }
            return true;
          }

          // remove all existing markers and one at specified latitude and longitude
          function remove_all_markers_and_add_one_to(map, latitude, longitude, draggable, text) {
            // clears all overlays (info boxes, markers etc)
            map.clearOverlays();
            // create the marker (draggable is passed in as either true or false)
            map.current_marker = new GMarker(new GLatLng(latitude, longitude), {draggable: draggable});
            // add the marker to the map
            map.addOverlay(map.current_marker);
            // add a text bubble if needed
            if (text) { map.current_marker.openInfoWindowHtml(text); }
            // when a user stops dragging the marker, update the coords and zoom level
            google.maps.Event.addListener(map.current_marker, 'dragend', function() {
              // update the map data field
              update_map_data(map, map.current_marker.getLatLng());
            });
          }

          // updates the map with a marker and text bubble with street address
          function update_map_data(map, latlng_obj) {
            // Form a a string like   -45.861836,127.398373  (which is the format we use)
            $(map.latlng_text_field).value = latlng_obj.y + ',' + latlng_obj.x;
            // the current maps zoom level
            $(map.zoom_text_field).value = map.getZoom();
            // add a marker on where the user just clicked/drag marker to
            remove_all_markers_and_add_one_to(map, latlng_obj.y, latlng_obj.x, true);
            // Attempt to get the address. When it succeeds, it'll reposition the marker to the location
            // the address corresponds to, and update the text/fields as well (to keep data current)
            map.geocoder_obj.getLocations(latlng_obj, function(response) {
              if (!response || response.Status.code != 200) {
                // if something went wrong, give the status code. This should rarely happen.
                alert('Status Code:' + response.Status.code);
              } else {
                // get the place
                place = response.Placemark[0];
                // if the place result is accurate enough (6-10 accuracy)
                // if it isn't, we end up clicking and getting sent half way across the country
                if (place.AddressDetails.Accuracy > 5) {
                  // create the text used in a bubble soon
                  text = '<b>Address:</b>' + place.address + '<br>' +
                         '<b>Accuracy:</b>' + place.AddressDetails.Accuracy + '<br>' +
                         '<b>Country code:</b> ' + place.AddressDetails.Country.CountryNameCode;
                  // remove the marker set earlier and reposition it to the results location
                  remove_all_markers_and_add_one_to(map, place.Point.coordinates[1], place.Point.coordinates[0], true, text);
                  // Form a a string like   -45.861836,127.398373  (which is the format we use)
                  $(map.latlng_text_field).value = place.Point.coordinates[1] + ',' + place.Point.coordinates[0];
                  // the current maps zoom level
                  $(map.zoom_text_field).value = map.getZoom();
                  // the address details from the result
                  $(map.address_text_field).value = place.address;
                }
              }
            });
          }

          #{'// when the page has finished loading, then initiate the google map
            document.observe(\'dom:loaded\', function() { ' + @google_maps_initializers + ' });' unless @do_not_load_google_maps_on_page_load}
        ") + "\n"
        # We don't need the search controls and stylesheets on the index/show, only new/edit
        unless @google_map_on_index_or_show_page
          html += javascript_include_tag("http://www.google.com/uds/api?file=uds.js&amp;v=1.0&amp;key=#{@gma_config[:google_map_api][:api_key]}") + "\n"
          html += javascript_include_tag("http://www.google.com/uds/solutions/localsearch/gmlocalsearch") + "\n"
          html += stylesheet_link_tag("http://www.google.com/uds/css/gsearch.css") + "\n"
          html += stylesheet_link_tag("http://www.google.com/uds/solutions/localsearch/gmlocalsearch.css") + "\n"
        end
        html
      end
    end
  end

end