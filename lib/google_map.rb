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
          klass.send :before_filter, :prepare_google_map, :only => ['show', 'new', 'create', 'edit', 'update', 'preview']
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
        @google_map_on_index_or_show_page = true if ['index', 'show', 'preview'].include?(params[:action])
      end
    end
  end

  module ExtendedFieldsHelper
    def extended_field_map_editor(name, value, extended_field, options = {}, latlng_options = {}, generate_text_fields = true, display_coords = false, display_address = false)
      raise "ERROR: extended_field param should be of ExtendedField class, not #{extended_field.class.name}" unless extended_field.is_a?(ExtendedField)
      field_type = extended_field.ftype

      # Google maps are disabled by default, so make sure we enable them here
      # This method is called on all pages
      @using_google_maps = true

      # we fill the text field values in one of two ways
      # first, if the new/edit form has been submitted, we use those values
      # second, if we're editing but not submitted yet, we use the items values
      # if they still don't exist by now, we'll determine them in JS later

      @current_coords = ''
      @current_zoom_lvl = ''
      @current_address = ''
      @do_not_use_map = false
      if !param_from_field_name(name).blank?
        # these values are coming from a submitted new/edit form
        @current_coords = param_from_field_name(name)[:coords] || ''
        @current_zoom_lvl = param_from_field_name(name)[:zoom_lvl] || ''
        @current_address = param_from_field_name(name)[:address] || ''
        @do_not_use_map = (param_from_field_name(name)[:no_map] == "1") || false
      elsif !value.blank?
        # these values are coming from an edited item
        begin
          @current_coords = value['coords'] || ''
          @current_zoom_lvl = value['zoom_lvl'] || ''
          @current_address = value['address'] || ''
          @do_not_use_map = (value['no_map'] == "1") || false
        rescue
        end
      end

      # create a safe name (letters and underscores only) from the field name
      safe_name = create_safe_extended_field_string(name)

      # populate a map data hash with details for this map (can have multiple maps on each item)
      map_data = { :map_id => "#{safe_name}_map_div",
                   :map_type => field_type,
                   :latitude => @current_coords.split(',')[0],
                   :longitude => @current_coords.split(',')[1],
                   :zoom_lvl => @current_zoom_lvl,
                   :address => @current_address,
                   :no_map => @do_not_use_map,
                   :coords_field => "#{safe_name}_map_coords_value",
                   :zoom_lvl_field => "#{safe_name}_map_zoom_value",
                   :address_field => "#{safe_name}_map_address" }
      # an array of maps to be displayed on this page
      @google_maps_list ||= Array.new
      @google_maps_list << map_data

      html = String.new
      unless @google_map_on_index_or_show_page && @do_not_use_map
        if generate_text_fields
          # if we're on the edit pages, we want these fields to be present
          fields = String.new
          if field_type == 'map_address'
            fields += label_tag(map_data[:address_field], I18n.t('google_map_lib.extended_field_map_editor.address'), :class => 'inline') +
                      text_field_tag("#{name}[address]",
                                      @current_address,
                                     { :id => map_data[:address_field], :size => 45 }) + "<br />"
          end
          fields += label_tag(map_data[:coords_field], I18n.t('google_map_lib.extended_field_map_editor.lat_lng'), :class => 'inline') +
                    text_field_tag("#{name}[coords]",
                                    @current_coords,
                                   { :id => map_data[:coords_field] }) + "<br />"
          fields += label_tag(map_data[:zoom_lvl_field], I18n.t('google_map_lib.extended_field_map_editor.zoom_lvl'), :class => 'inline') +
                    text_field_tag("#{name}[zoom_lvl]",
                                    @current_zoom_lvl,
                                   { :id => map_data[:zoom_lvl_field], :size => 2 })
          html += content_tag('div', fields, { :id => "#{map_data[:map_id]}_fields" })
          html += content_tag('div', I18n.t('google_map_lib.extended_field_map_editor.need_exact_data'),
                                     { :id => "#{map_data[:map_id]}_warning" })
        end

        # If we're on the show pages, and the map type shows the address
        # append a paragraph after the google map with the address value
        html += content_tag('p', @current_address,
                            :id => "#{map_data[:map_id]}_address",
                            :style => 'padding: 0; margin: 0;') if display_address

        # create the lat/lng display
        latlng_data = { :style => 'width:550px;' }.merge(latlng_options)
        latlng_data[:style] = "#{latlng_data[:style]} margin:0px; text-align:right;"

        if !extended_field.base_url.blank?
          gma_config = YAML.load(IO.read(File.join(RAILS_ROOT, 'config/google_map_api.yml')))
          latlng_param = gma_config[:google_map_api][:latlng_param] || 'll'
          zoom_lvl_param = gma_config[:google_map_api][:zoom_lvl_param] || 'z'
          coords_text = link_to(@current_coords, "#{extended_field.base_url}#{latlng_param}=#{@current_coords}&#{zoom_lvl_param}=#{@current_zoom_lvl}")
        else
          coords_text = @current_coords
        end

        html += content_tag('p', "<a href='#' id='#{map_data[:coords_field]}_show_hide' style='display:none;'>
                                    <small>#{I18n.t('google_map_lib.extended_field_map_editor.show_lat_lng')}</small>
                                  </a><br />
                                  <em id='#{map_data[:coords_field]}_display'>
                                    <span id='#{map_data[:coords_field]}_display_label'>#{I18n.t('google_map_lib.extended_field_map_editor.lat_lng')}</span>
                                    #{coords_text}
                                  </em>",
                                 latlng_data) if display_coords

        # create the google map div
        map_options = { :style => 'width:550px;' }.merge(options)
        html += content_tag('div', "<small>(#{I18n.t('google_map_lib.extended_field_map_editor.need_javascript')})</small>", map_options.merge({:id => map_data[:map_id], :class => 'google_map_container'}))
        if generate_text_fields
          controller = (@new_item_controller || params[:controller])
          # this is the current topic_type from form
          # which may not be the topic_type that is actually mapped to extended_field
          # it might be an ancestor, we will look up actual topic_type in is_required?
          topic_type_id = controller == 'topics' ? (params[:new_item_topic_type] || (params[:topic] && params[:topic][:topic_type_id]) || current_item.topic_type.id) : nil
          html += hidden_field_tag("#{name}[no_map]", "0")
          unless extended_field.is_required?(controller, topic_type_id)
            html += "OR #{check_box_tag("#{name}[no_map]", "1", @do_not_use_map)} <strong>#{I18n.t('google_map_lib.extended_field_map_editor.no_location')}</strong>"
          end
        end
      end

      html
    end
    # both the google map and google map with address options use the same code
    def extended_field_map_address_editor(name, value, extended_field, options = {}, latlng_options = {}, generate_text_fields = true, display_coords = false, display_address = false)
      raise "ERROR: extended_field param should be of ExtendedField class, not #{extended_field.class.name}" unless extended_field.is_a?(ExtendedField)
      extended_field_map_editor(name, value, extended_field, options, latlng_options, generate_text_fields, display_coords, display_address)
    end

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
      # the values passed in should form a Hash
      return I18n.t('google_map_lib.validate_extended_map_field_content.not_a_hash',
                    :class => values.class.name,
                    :value => values.inspect) unless values.is_a?(Hash)
      # allow the user to not provide a map if they don't want to
      return nil if values['no_map'] == "1"
      # check if this field is required and not set
      if values['coords'].nil? || values['zoom_lvl'].nil?
        if extended_field_mapping.required
          return I18n.t('google_map_lib.validate_extended_map_field_content.not_present_required')
        else
          return I18n.t('google_map_lib.validate_extended_map_field_content.not_present_optional')
        end
      end
      # check here that [0] is the zoom, [1] is the coords, [2] is the hide/no map option, and [3] is the address
      wrong_format = false
      begin
        wrong_format = true unless (values['zoom_lvl'] == '0' || values['zoom_lvl'].to_i > 0) &&
                                  (values['coords'].split(',').size == 2) &&
                                  (['0','1'].include?(values['no_map'])) &&
                                  (values['address'].blank? || values['address'].is_a?(String))
      rescue
        wrong_format = true
      end
      return I18n.t('google_map_lib.validate_extended_map_field_content.wrong_format',
                    :class => values.class.name,
                    :value => values.inspect) if wrong_format
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
          next if google_map[:no_map] && @google_map_on_index_or_show_page
          @google_maps_initializers += "initialize_google_map("
          @google_maps_initializers += "'#{google_map[:map_id]}'"
          @google_maps_initializers += ", '#{google_map[:map_type]}'"
          @google_maps_initializers += (google_map[:latitude].blank? ? ", ''" : ", #{google_map[:latitude].to_f.to_s}")
          @google_maps_initializers += (google_map[:longitude].blank? ? ", ''" : ", #{google_map[:longitude].to_f.to_s}")
          @google_maps_initializers += (google_map[:zoom_lvl].blank? ? ", ''" : ", #{google_map[:zoom_lvl].to_i.to_s}")
          @google_maps_initializers += (google_map[:address].blank? ? ", ''" : ", '#{escape_javascript(google_map[:address])}'")
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
        return "<!-- Error: Trying to use Google Maps without configuation (config/google_map_api.yml) -->" unless File.exists?(@gma_config_path)
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
          function initialize_google_map(map_id, map_type, latitude, longitude, zoom_lvl, address, latlng_text_field, zoom_text_field, address_text_field) {
            // make sure we don't do any google map code unless the browser supports it
            if (!google.maps.BrowserIsCompatible()) {
              alert('#{i18n_js('google_map_lib.load_google_map_api.not_compatible')}'); return;
            }
            // check the google map div is present on the page before continuing
            if (!$(map_id)) {
              alert('#{i18n_js('google_map_lib.load_google_map_api.non_existant_div')} - ' + map_id); return;
            }
            // clear/resize the div on both displays, and replace the warning/hide the fields
            $(map_id).value = '';
            #{@google_map_on_index_or_show_page ? '$(map_id).setStyle({height: \'220px\'});
                                                   $(latlng_text_field + \'_display\').hide();
                                                   $(latlng_text_field + \'_display\').hidden_status = \'hidden\';
                                                   $(latlng_text_field + \'_display_label\').hide();
                                                   $(latlng_text_field + \'_show_hide\').show();
                                                   $(latlng_text_field + \'_show_hide\').observe(\'click\', function(event) {
                                                     if ($(latlng_text_field + \'_display\').hidden_status == \'hidden\') {
                                                       $(latlng_text_field + \'_display\').show();
                                                       $(latlng_text_field + \'_display\').hidden_status = \'showing\';
                                                       $(latlng_text_field + \'_show_hide\').update(\'<small>' + i18n_js('google_map_lib.load_google_map_api.hide_lat_lng') + '</small>\');
                                                     } else {
                                                       $(latlng_text_field + \'_display\').hide();
                                                       $(latlng_text_field + \'_display\').hidden_status = \'hidden\';
                                                       $(latlng_text_field + \'_show_hide\').update(\'<small>' +  i18n_js('google_map_lib.load_google_map_api.show_lat_lng') + '</small>\');
                                                     }
                                                     event.stop();
                                                   });
                                                   if (map_type == \'map_address\') {
                                                     $(map_id + \'_address\').hide();
                                                   }' :
                                                  '$(map_id).setStyle({height: \'380px\'});
                                                   $(map_id + \'_warning\').hide();
                                                   $(map_id + \'_fields\').hide();'}
            // initialize the google map
            var map = new google.maps.Map2($(map_id), {
              googleBarOptions: {
                onGenerateMarkerHtmlCallback: function(marker, html, result) {
                  // Intercept search results, and adjust the info bubble to provide a hook for
                  // updating the currently chosen location on a Google Map

                  var title = new Element('p').update('<strong>' + result.title + '</strong>');

                  var link = new Element('a', { href: '#' }).observe('click', function(event) {
                    resetCurrentSearchAndSetMarker(this);
                    event.stop();
                  });
                  link.update(\"#{i18n_js('google_map_lib.load_google_map_api.correct_location_yes')}\");
                  link.map = map;
                  link.marker = marker;

                  var confirmation = new Element('p').update('#{i18n_js('google_map_lib.load_google_map_api.correct_location')} ');
                  confirmation.appendChild(link);

                  var container = new Element('div');
                  container.appendChild(title);
                  container.appendChild(confirmation);

                  return container;
                }
              }
            });

            // disable dblclick for zoom because it conflicts with a click event
            map.disableDoubleClickZoom();
            // store the several objects/values in the map object for easy access
            // it also makes it possible to have different maps on the same page
            map.geocoder_obj = new google.maps.ClientGeocoder();
            map.map_type = map_type;
            map.latitude_value = latitude;
            map.longitude_value = longitude;
            map.zoom_lvl_value = zoom_lvl;
            map.latlng_text_field = latlng_text_field;
            map.zoom_text_field = zoom_text_field;
            if (map.map_type == 'map_address') {
              map.address_text_field = address_text_field;
              map.address_value = address;
              map.address_value_div_id = map_id + '_address';
            }
            // Make sure we have the nessesary fields present
            if (!verify_all_fields_present(map)) { return; }
            // center the map on the default latitude, longitude and zoom level
            // (comes from either params, the item being edited, or config)
            map.setCenter(new google.maps.LatLng(map.latitude_value, map.longitude_value), map.zoom_lvl_value);
            // add the small controls in the top left of the map (for moving and zooming)
            map.addControl(new google.maps.SmallMapControl());
            // if we are on the index/show page, dont show search controls, dont make markers draggable
            // else if we are on the new/edit pages, bind a search control to the map, and allow dragging
            #{@google_map_on_index_or_show_page ? 'remove_all_markers_and_add_one_to(map, map.latitude_value, map.longitude_value, false, \'\', false, map.address_value_div_id);' \
                                                : 'map.enableGoogleBar(); remove_all_markers_and_add_one_to(map, map.latitude_value, map.longitude_value, true);'}
            // the code from this point only executes on new/edit pages, not the show pages
            if ($(map.latlng_text_field) && $(map.zoom_text_field) && (map.map_type == 'map' || (map.map_type == 'map_address' && $(map.address_text_field)))) {
              // make readonly
              $(map.latlng_text_field).readonly = true;
              $(map.zoom_text_field).readonly = true;
              if (map.map_type == 'map_address') {
                $(map.address_text_field).readonly = true;
              }
              // when a user clicks the map, add a marker and update the coords and zoom level
              google.maps.Event.addListener(map, 'click', function(overlay, latlng) {
                // make sure that a latitude and longitude is passed in
                if (latlng) {
                  // update the map data field
                  update_map_data(map, latlng);
                }
              });
              // when a user stops dragging/zooming, update the zoom level (not the coords, thats what the pinpoint is for)
              google.maps.Event.addListener(map, 'zoomend', function(old_zoom_lvl, new_zoom_lvl) {
                $(map.zoom_text_field).value = new_zoom_lvl;
              });
            } else {
              #{!@google_map_on_index_or_show_page ?
                "alert('#{i18n_js('google_map_lib.load_google_map_api.fields_dont_exist')}');" :
                "// do nothing"}
            }
          }

          // Clears the results (by disabling and reenabling the google map)
          // And updates the map with the marker to point at the result chosen
          function resetCurrentSearchAndSetMarker(link) {
            link.map.disableGoogleBar();
            link.map.enableGoogleBar();
            update_map_data(link.map, link.marker.getLatLng());
          }

          // make sure the fields are filled in, and error out if they arn't at the end
          function verify_all_fields_present(map) {
            // If these values are blank, make one last attempt to add values to them
            // Do this by first seeing if we can get the users location, and if not
            // Use the default lat/lng/zoom in the kete's google api config file
            if (map.latitude_value == '') {
              if (google.loader.ClientLocation.latitude) { map.latitude_value = google.loader.ClientLocation.latitude; }
              else { map.latitude_value = #{@default_latitude.to_f.to_s}; }
            }
            if (map.longitude_value == '') {
              if (google.loader.ClientLocation.longitude) { map.longitude_value = google.loader.ClientLocation.longitude; }
              else { map.longitude_value = #{@default_longitude.to_f.to_s}; }
            }
            if (map.zoom_lvl_value == '') { map.zoom_lvl_value = #{@default_zoom_lvl.to_i.to_s}; }
            // If the values arn't populated by now (after 4 different sources), something went wrong.
            if (map.latitude_value == '' || map.longitude_value == '' || map.zoom_lvl_value == '') {
              alert('#{i18n_js('google_map_lib.load_google_map_api.lat_lng_not_set')}'); return false;
            }
            // Make sure that the three values are floats as needed by Google maps
            if (isNaN(parseFloat(map.latitude_value, 10)) || isNaN(parseFloat(map.longitude_value, 10)) || isNaN(parseInt(map.zoom_lvl_value, 10))) {
              alert('#{i18n_js('google_map_lib.load_google_map_api.lat_lng_not_floats')}'); return false;
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
          function remove_all_markers_and_add_one_to(map, latitude, longitude, draggable, text, auto_open, address_value_div_id) {
            // clears all overlays (info boxes, markers etc)
            map.clearOverlays();
            // create a latlng object from the values passed in
            latlng = new GLatLng(latitude, longitude);
            // create the marker (draggable is passed in as either true or false)
            map.current_marker = new GMarker(latlng, {draggable: draggable});
            // center the map on this new marker
            map.setCenter(latlng);
            // add the marker to the map
            map.addOverlay(map.current_marker);
            // add a text bubble if needed
            if (address_value_div_id) {
              google.maps.Event.addListener(map.current_marker, 'click', function() {
                $(address_value_div_id).toggle();
              });
            } else if (text) {
               if (auto_open) {
                map.current_marker.openInfoWindowHtml(text);
              } else {
                map.current_marker.bindInfoWindowHtml(text);
              }
            }
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
            // Attempt to get the address. When it succeeds, it'll reposition the marker to the location
            // the address corresponds to, and update the text/fields as well (to keep data current)
            map.geocoder_obj.getLocations(latlng_obj, function(response) {
              if (!response || response.Status.code != 200) {
                // if something went wrong, give the status code. This should rarely happen.
                if (response.Status.code == '602') {
                  var text = '#{i18n_js('google_map_lib.load_google_map_api.something_went_wrong_602')} (' + response.Status.code + ')';
                } else {
                  var text = '#{i18n_js('google_map_lib.load_google_map_api.something_went_wrong')} (' + response.Status.code + ')';
                }
                remove_all_markers_and_add_one_to(map, latlng_obj.y, latlng_obj.x, true, text, true);
              } else {
                // get the place
                var place = response.Placemark[0];
                // if the place result is accurate enough (6-10 accuracy)
                // if it isn't, we end up clicking and getting sent half way across the country
                if (place.AddressDetails.Accuracy > 5) {
                  // create the text used in a bubble soon
                  var text = '<b>#{i18n_js('google_map_lib.load_google_map_api.address')}</b>' + place.address + '<br>' +
                             '<b>#{i18n_js('google_map_lib.load_google_map_api.accuracy')}</b>' + place.AddressDetails.Accuracy + '<br>' +
                             '<b>#{i18n_js('google_map_lib.load_google_map_api.country_code')}</b> ' + place.AddressDetails.Country.CountryNameCode;
                  // remove the marker set earlier and reposition it to the results location
                  remove_all_markers_and_add_one_to(map, place.Point.coordinates[1], place.Point.coordinates[0], true, text, true);
                  // Form a a string like   -45.861836,127.398373  (which is the format we use)
                  $(map.latlng_text_field).value = place.Point.coordinates[1] + ',' + place.Point.coordinates[0];
                  // the current maps zoom level
                  $(map.zoom_text_field).value = map.getZoom();
                  if (map.map_type == 'map_address') {
                    // the address details from the result
                    $(map.address_text_field).value = place.address;
                  }
                } else {
                  var text = '#{i18n_js('google_map_lib.load_google_map_api.not_close_enough')}';
                  remove_all_markers_and_add_one_to(map, latlng_obj.y, latlng_obj.x, true, text, true);
                }
              }
            });
          }

          #{'// when the page has finished loading, then initiate the google map
            google.setOnLoadCallback(function() { ' + @google_maps_initializers + ' });' unless @do_not_load_google_maps_on_page_load}
        ") + "\n"
        # We don't need the search controls and stylesheets on the index/show, only new/edit
        unless @google_map_on_index_or_show_page
          html += javascript_include_tag("http://www.google.com/jsapi?key=#{@gma_config[:google_map_api][:api_key]}&format=")
        end
        html
      end
    end

    # anything we put into javascript needs to be specially escaped
    # to prevent JS from breaking and stopping the site from working
    def i18n_js(key)
      escape_javascript I18n.t(key)
    end
  end

end
