# what this does:
# * prepares google map accordingly for request type
#  (form for baskets_controller#choose_type with empty map, display for index_page_controller#index,
#   all other controllers#show, new, etc.)
# * adds view helpers for loading api js lib and initializing google map js and escaping js (i18n_js(key))
# * adds helpers for ExtendedFieldsHelper editor (including geocoding address form) and display
# * validates extended field ftype for map or map with address
module GoogleMap
  module Mapper
    ITEM_ACTIONS = %w{show new create edit update preview render_item_form}

    unless included_modules.include? GoogleMap::Mapper
      def self.included(klass)
        case klass.name
        when 'BasketsController'
          klass.send :before_filter, :prepare_google_map_without_instantiation, :only => ['choose_type']
        when 'IndexPageController'
          klass.send :before_filter, :prepare_google_map, :only => ['index']
        else
          klass.send :before_filter, :prepare_google_map, :only => ITEM_ACTIONS
        end
        klass.helper GoogleMap::ViewHelpers
      end

      private

      # new item
      def prepare_google_map_without_instantiation
        # turn it on here because we dont rerender the application template when we load a form via AJAX
        # so if the JS isn't already there on loading, then we run into errors
        @using_google_maps = true

        # the basket ajax item adder doesn't need the code run when the page is loaded,
        # only later when the form is generated, so set it not to do this
        @do_not_load_google_maps_on_page_load = true
      end

      # either show on index_page_controller, show/preview on item specific controller, or edit on item specific controller
      def prepare_google_map
        # just because the module was include doesn't mean this page has map extended fields. we'll set this true later
        # (in the extended_field_map_editor method below) when looping over the fields that call the method
        @using_google_maps = false

        # we don't want the local search field o draggable markers, etc.
        # on the index page or item show page, only new/edit pages
        if ['index', 'show', 'preview'].include?(params[:action])
          @google_map_on_index_or_show_page = true
          @do_not_load_google_maps_on_page_load = false
        else
          @google_map_on_index_or_show_page = false
          @do_not_load_google_maps_on_page_load = true
        end
      end
    end
  end

  module ExtendedFieldsHelper
    # default settings are for appearing in a form, not on show/index page
    def extended_field_map_editor(name, value, extended_field, options = {}, latlng_options = {}, generate_text_fields = true, display_coords = false, display_address = false)
      raise "ERROR: extended_field param should be of ExtendedField class, not #{extended_field.class.name}" unless extended_field.is_a?(ExtendedField)
      field_type = extended_field.ftype

      # Google maps are disabled by default, so make sure we enable them here
      # This method is called on all pages
      @using_google_maps = true

      set_gm_defaults if !@google_map_on_index_or_show_page

      # we fill the text field values in one of two ways
      # first, if the new/edit form has been submitted, we use those values
      # second, if we're editing but not submitted yet, we use the items values
      # if they still don't exist by now, we'll determine them in JS later

      @current_coords = ''
      @current_zoom_lvl = ''
      @current_address = ''
      @do_not_use_map = false

      param_field_name = param_from_field_name(name)
      if !param_field_name.blank?
        # these values are coming from a submitted new/edit form
        @current_coords = param_field_name[:coords] || ''
        @current_zoom_lvl = param_field_name[:zoom_lvl] || ''
        @current_address = param_field_name[:address] || ''
        @do_not_use_map = (param_field_name[:no_map] == "1") || false
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
        :address_field => "#{safe_name}_map_address",
        :no_map_field => "#{safe_name}_no_map"
      }

      form_field_ids = map_data.to_a.inject(Array.new) do |ids, pair|
        form_field_id_name = pair.first.to_s
        if form_field_id_name.include?('field')
          ids << pair.last if !form_field_id_name.include?('address') || (map_data[:map_type] == 'map_address')
        end
        ids
      end

      # add to the array of maps to be displayed on this page
      @google_maps_list ||= Array.new
      @google_maps_list << map_data

      @maps_callbacks ||= Array.new

      html = String.new

      # skip adding a map if this is a show (or index_page index) action
      # AND the particular map is "do not show map" as its value
      if !(@google_map_on_index_or_show_page && @do_not_use_map)
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
        # change class value accordingly
        # default is wider, editor specifies narrow for add/edit use
        latlng_data = { :class => 'extended_field_form_map' }.merge(latlng_options)
        latlng_data[:style] = "margin:0px; text-align:right;"

        if extended_field.base_url.present?
          latlng_param = 'll' # @gm_config[:google_map_api][:latlng_param] || 'll'
          zoom_lvl_param =  'z' # @gm_config[:google_map_api][:zoom_lvl_param] || 'z'
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

        if generate_text_fields && Kete.enable_maps?
          # If we're on the add/edit form
          # append a text input that we can use with Google Maps Places aspect of the API
          # see places library addition below
          html += label_tag("#{map_data[:map_id]}_search_label",
                            I18n.t('google_map_lib.extended_field_map_editor.search_for_location'), 
                            :class => 'inline') +
            text_field_tag(I18n.t('google_map_lib.extended_field_map_editor.search_for_location'), "",
                           { :id => "#{map_data[:map_id]}_search",
                             :size => 68,
                             :style => 'padding: 0; margin: 0;',
                             :placeholder => I18n.t('google_map_lib.extended_field_map_editor.search_for_location_placeholder',
                                                    :field_label => extended_field.label)
                           })
        end

        if Kete.enable_maps?
          # create the google map div
          # change class value accordingly
          # default is wider, editor specifies narrow for add/edit use
          map_options = { :class => 'extended_field_form_map' }.merge(options)
          
          gmaps_options = HashWithIndifferentAccess.new
          gmaps_options[:map_options] = { :id => map_data[:map_id],
            :container_id => "map_container_#{map_data[:map_id]}",
            :container_class => "#{map_options[:class]}",
            :class => "#{map_options[:class]}",
            :auto_adjust => false,
            :disableDoubleClickZoom => true,
            :zoom => @current_zoom_lvl.to_i }

          unless @google_map_on_index_or_show_page
            gmaps_options[:map_options][:libraries] = ['places']
            gmaps_options[:map_options][:draggable] = true
          end

          # is this the first call to gmaps?
          # if so, load js files
          # else skip
          gmaps_options[:last_map] = false
          if @google_maps_list.size > 1
            gmaps_options[:scripts] = :none
          end

          # if there is a value, add a marker (which will use it as center) by constructing json
          # else set values for centering the map and zoom level
          markers = Array.new
          markers_map_options = HashWithIndifferentAccess.new
          markers_options = HashWithIndifferentAccess.new

          # how it should work:
          # no value = no initial marker
          # no value = center lat/lng resolves to default OR detected location
          # no value = DO NOT RECORD LOCATION checked
          # click places a marker
          # search creates marker
          # as soon as marker set, DO NOT RECORD LOCATION unchecked
          if map_data[:latitude].present?
            marker_hash = { :lat => map_data[:latitude].to_f,
              :lng => map_data[:longitude].to_f }

            markers << marker_hash

            markers_map_options = {
              :center_latitude => map_data[:latitude].to_f,
              :center_longitude => map_data[:longitude].to_f,
              :zoom => map_data[:zoom_lvl].to_i}

            markers_map_options[:disableDoubleClickZoom] = false if @google_map_on_index_or_show_page

          else
            
            gmaps_options[:map_options] = gmaps_options[:map_options].merge({ :detect_location => true,
                                                                              :center_on_user => true,
                                                                              :center_latitude => @default_latitude.to_f,
                                                                              :center_longitude => @default_longitude.to_f,
                                                                              :zoom => @default_zoom_lvl.to_i
                                                                            })
          end


          gmaps_options[:markers] = { :data => markers.to_json }

          markers_options[:draggable] = true unless @google_map_on_index_or_show_page
          gmaps_options[:markers][:options] = markers_options if markers_options.present?

          gmaps_options[:map_options] = gmaps_options[:map_options].merge(markers_map_options) if markers_map_options.present?

          # add needed functions
          # hide/show text fields

          html += gmaps(gmaps_options)

          if generate_text_fields
            controller = (@new_item_controller || params[:controller])
            # this is the current topic_type from form
            # which may not be the topic_type that is actually mapped to extended_field
            # it might be an ancestor, we will look up actual topic_type in is_required?
            topic_type_id = controller == 'topics' ? (params[:new_item_topic_type] || (params[:topic] && params[:topic][:topic_type_id]) || current_item.topic_type.id) : nil
            html += hidden_field_tag("#{name}[no_map]", "0")
            unless extended_field.is_required?(controller, topic_type_id)
              # id here is standard id generated is #{name}_no_map
              @do_not_use_map = true if %w{render_item_form new}.include?(params[:action]) && @current_coords.blank?
              html += "OR #{check_box_tag("#{name}[no_map]", "1", @do_not_use_map)} <strong>#{I18n.t('google_map_lib.extended_field_map_editor.no_location')}</strong>"
            end
          end

          js = String.new

          if @google_map_on_index_or_show_page
            # for non-add/edit (show, index pages) maps

            js += set_height_for(map_data[:map_id], 220) + ' '

            # initialize latlng_value_viewer and set up toggle so it can be shown
            js += set_display_state_for(map_data[:coords_field]) + ' '
            js += set_click_observer_on_show_hide_toggle_for(map_data[:coords_field])

          else
            # for add/edit maps
            js += define_supporting_functions + ' ' if @google_maps_list.size == 1

            js += hide_warning_and_form_fields_for(map_data[:map_id]) + ' '

            # click do not record location clears all markers?
            js += add_no_map_observer_for(safe_name, map_data[:map_id])

            js_callback = ["Gmaps.#{map_data[:map_id]}.callback = function() {"]

            js_callback << set_height_for(map_data[:map_id], 380)

            js_callback << add_field_attributes_to_map_from(map_data)

            js_callback << disable_form_fields_for(form_field_ids)

            js_callback << add_click_listener_for(map_data[:map_id])

            js_callback << add_dragend_listener_for_markers_of(map_data[:map_id])

            js_callback << add_zoomend_listener_for(map_data[:map_id], map_data[:zoom_lvl_field])

            # activate search box
            js_callback << add_places_autocomplete_to_search_location_for("#{map_data[:map_id]}_search", map_data[:map_id])

            js_callback << "}"

            @maps_callbacks << js_callback.join(' ')
          end

          html += javascript_tag(js)
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
    def set_height_for(map_id, size)
      "$('#{map_id}').setStyle({height: '#{size}px'});"
    end

    def add_field_attributes_to_map_from(map_data)
      map_id = map_data[:map_id]
      "Gmaps.#{map_id}.latlng_text_field = '#{map_data[:coords_field]}';
       Gmaps.#{map_id}.zoom_text_field = '#{map_data[:zoom_lvl_field]}';
       Gmaps.#{map_id}.address_text_field = '#{map_data[:address_field]}';
       Gmaps.#{map_id}.no_map_field = '#{map_data[:no_map_field]}';
       Gmaps.#{map_id}.map_fields_type = '#{map_data[:map_type]}';
       "
    end

    def set_display_state_for(latlng_value_viewer, to_state = 'hide')
      js = "$('#{latlng_value_viewer + '_display'}').#{to_state}();"

      js += " $('#{latlng_value_viewer + '_display'}').hidden_status = "
      if to_state == 'hide'
        js += "'hidden';"
      else
        js += "'showing';"
      end

      js += " $('#{latlng_value_viewer + '_display_label'}').#{to_state}();"

      update_text = to_state == 'hide' ? i18n_js('google_map_lib.set_display_state_for.show_lat_lng') : i18n_js('google_map_lib.set_display_state_for.hide_lat_lng')

      js += " $('#{latlng_value_viewer + '_show_hide'}').update('<small>#{update_text}</small>\');"
      
      js += " $('#{latlng_value_viewer + '_show_hide'}').show();"

      js
    end
    
    def set_click_observer_on_show_hide_toggle_for(latlng_value_viewer)
      # js trimmed out from end, may want to reinstate
      # " if (map_type == \'map_address\') {
      #  $(map_id + \'_address\').hide();
      # }"
      "$('#{latlng_value_viewer + '_show_hide'}').observe('click', function(event) {
         if ($('#{latlng_value_viewer + '_display'}').hidden_status == 'hidden') {
           #{set_display_state_for(latlng_value_viewer, 'show')}
         } else {
           #{set_display_state_for(latlng_value_viewer)}
         }
         event.stop();
         });"
    end

    def hide_warning_and_form_fields_for(map_id)
      "$('#{map_id + '_warning'}').hide();
       $('#{map_id + '_fields'}').hide();"
    end

    def disable_form_fields_for(form_field_ids)
      js = form_field_ids.inject(String.new) do |js, field_id|
        js += "$('#{field_id}').readonly = true;"
      end
      js
    end

    # unfortunately because the id isn't unique for the checkbox, we have to iterate through all checkboxes
    def add_no_map_observer_for(field_id_stub, map_id)
       "$$('input[type=\"checkbox\"]').each( function(box) {
          if (box.id !== '' && typeof box.id !== 'undefined' && box.id === '#{field_id_stub}_no_map') {
            box.observe('click', function(event) { keteMaps.noMapClickedFor(Gmaps.#{map_id}, this.checked); });
          }
        });"
    end

    def add_click_listener_for(map_id)
      "// when a user clicks the map, add a marker and update the coords and zoom level
       google.maps.event.addListener(Gmaps.#{map_id}.map, 'click', function(event) {
           keteMaps.updateMapData(Gmaps.#{map_id}, event.latLng);
        });"
    end

    def add_zoomend_listener_for(map_id, zoom_field)
      "// when a user stops dragging/zooming, update the zoom level (not the coords, thats what the pinpoint is for)
       google.maps.event.addListener(Gmaps.#{map_id}.map, 'zoom_changed', function() {
         $('#{zoom_field}').value = Gmaps.#{map_id}.map.getZoom();
       });"
    end

    def add_dragend_listener_for_markers_of(map_id)
      "// when a user drags a marker on the map, clear other markers, and update based on this one
       keteMaps.addDragendListenerForMarkersOf(Gmaps.#{map_id});
       "
    end

    def add_places_autocomplete_to_search_location_for(search_field_for_the_map, map_id)
      "autocomplete = new google.maps.places.Autocomplete($('#{search_field_for_the_map}'));
       autocomplete.bindTo('bounds', Gmaps.#{map_id}.map);

       google.maps.event.addListener(autocomplete, 'place_changed', function() {
         var newPlace = this.getPlace();
         var newLatValue = newPlace.geometry.location.lat();
         var newLngValue = newPlace.geometry.location.lng();

         newLatLng = new google.maps.LatLng(newLatValue, newLngValue);

         // move map centering to fit newLatLng, this maintains zoom level
         Gmaps.#{map_id}.map.setCenter(newLatLng);

         keteMaps.updateMapData(Gmaps.#{map_id}, newLatLng, newPlace);
       });
      "
    end

    def define_supporting_functions
      "keteMaps.addDragendListenerForMarkersOf = function(gmaps4RailsMap) {
         var markers_to_monitor = gmaps4RailsMap.markers;

         for (var i = 0; i <  markers_to_monitor.length; ++i) {
           google.maps.event.addListener(markers_to_monitor[i].serviceObject, 'dragend', ( function(map) {
              return function(event) { keteMaps.updateMapData(map, event.latLng); }
          } )(gmaps4RailsMap)
          );
         }
       };

       keteMaps.updatePlaceFieldsFor = function(gmaps4RailsMap, place) {
         $(gmaps4RailsMap.latlng_text_field).value = place.geometry.location.lat() + ',' + place.geometry.location.lng();

         if (gmaps4RailsMap.map_fields_type == 'map_address') {
           $(gmaps4RailsMap.address_text_field).value = place.formatted_address;
         }
       };
       
       keteMaps.noMapClickedFor = function(gmaps4RailsMap, checked_value) {
         if (checked_value) {
           // clear map
           gmaps4RailsMap.clearMarkers();
           
          $(gmaps4RailsMap.latlng_text_field).value = '';
          $(gmaps4RailsMap.zoom_text_field).value = '';

          if (gmaps4RailsMap.map_fields_type == 'map_address') {
             $(gmaps4RailsMap.address_text_field).value = '';
          }           
         }
       };

       keteMaps.updateMarkersForWith = function(gmaps4RailsMap, markerData) {
            var newMarkers = [markerData];

            gmaps4RailsMap.replaceMarkers(newMarkers);
            
            if (markerData.description !== '' && typeof markerData.description !== 'undefined') {
              var infoWindow = new google.maps.InfoWindow({
               content: markerData.description
              });

              infoWindow.open(gmaps4RailsMap.map, gmaps4RailsMap.markers[0].serviceObject);
              gmaps4RailsMap.visibleInfoWindow = infoWindow;
            }

            // Add dragend listener on marker by refreshing maps listeners on its markers
            keteMaps.addDragendListenerForMarkersOf(gmaps4RailsMap);
       };

       keteMaps.updateMapData = function(gmaps4RailsMap, latlng_obj, place) {
            var latValue = latlng_obj.lat(),
              lngValue = latlng_obj.lng(),
              infoWindowText = '';
            
            var markerData = { 
              lat: latValue,
              lng: lngValue,
              description: null,
              draggable: true };

            // in most cases the zoom level value will already be set, leave as is, but if new value is set, may not be
            if ($(gmaps4RailsMap.zoom_text_field).value === '' || typeof $(gmaps4RailsMap.zoom_text_field).value === 'undefined') {
              $(gmaps4RailsMap.zoom_text_field).value = gmaps4RailsMap.map.getZoom();
            }

            if (place !== '' && typeof place !== 'undefined') {
              markerData.description = '<b>#{i18n_js('google_map_lib.define_supporting_functions.address')}</b>' + place.formatted_address;
              keteMaps.updatePlaceFieldsFor(gmaps4RailsMap, place);
              keteMaps.updateMarkersForWith(gmaps4RailsMap, markerData);
            } else {
              // Attempt to get the address. When it succeeds, it'll reposition the marker to the location
              // the address corresponds to, and update the text/fields as well (to keep data current)
              var geocoder = new google.maps.Geocoder();

              geocoder.geocode({ latLng: latlng_obj }, function(results, status) {
                if (status !== google.maps.GeocoderStatus.OK) {
                  // if something went wrong, give the status code. This should rarely happen.
                  if (status === google.maps.GeocoderStatus.ZERO_RESULTS) {
                    infoWindowText = '#{i18n_js('google_map_lib.define_supporting_functions.something_went_wrong_602')}';
                  } else {
                    infoWindowText = '#{i18n_js('google_map_lib.define_supporting_functions.something_went_wrong')}';
                  }
                  markerData.description = infoWindowText + ' (' + status + ')';
                } else {
                  // get the place
                  var place = results[0];

                  markerData.description = '<b>#{i18n_js('google_map_lib.define_supporting_functions.address')}</b>' + place.formatted_address;
                  keteMaps.updatePlaceFieldsFor(gmaps4RailsMap, place);
                }
                keteMaps.updateMarkersForWith(gmaps4RailsMap, markerData);
              });
            }

            // because of the non-unique checkbox ids for no_map, we have to iterate over all of them
            $$('input[type=\"checkbox\"]').each( function(box) {
              if (box.id !== '' && typeof box.id !== 'undefined' && box.id === gmaps4RailsMap.no_map_field) {
                box.checked = false;
              }
            });

          };"
    end

    # Get the default latitude, longitude, and zoom level just in case we need them later
    def set_gm_defaults
      return if @default_latitude && @default_longitude && @default_zoom_lvl

      if Kete.default_latitude.present? ||
          Kete.default_longitude.present?

        @default_latitude = Kete.default_latitude
        @default_longitude = Kete.default_longitude
      end

      if Kete.default_zoom_level.present?
        @default_zoom_lvl = Kete.default_zoom_level
      end
    end

    def load_maps_javascript_files
      html = javascript_include_tag("http://maps.google.com/maps/api/js?sensor=false&amp;libraries=geometry,places").sub('.js', '') + ' '
      html += javascript_include_tag("http://google-maps-utility-library-v3.googlecode.com/svn/tags/infobox/1.1.5/src/infobox.js") + ' '
      html += javascript_include_tag("http://google-maps-utility-library-v3.googlecode.com/svn/tags/markerclusterer/1.0/src/markerclusterer_compiled.js") + ' '
      html += javascript_include_tag('gmaps4rails/gmaps4rails.base.js') + ' '
      html += javascript_include_tag 'gmaps4rails/gmaps4rails.googlemaps.js'
      html
    end

    # anything we put into javascript needs to be specially escaped
    # to prevent JS from breaking and stopping the site from working
    def i18n_js(key)
      escape_javascript I18n.t(key)
    end
  end

end

require 'gmaps4rails/base'
# require 'gmaps4rails/acts_as_gmappable'
require 'gmaps4rails/extensions/array'
require 'gmaps4rails/extensions/hash'
require 'gmaps4rails/helper/gmaps4rails_helper'
ActionController::Base.send :helper, Gmaps4railsHelper
