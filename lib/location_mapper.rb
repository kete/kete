include ActionView::Helpers::JavaScriptHelper
include ActionView::Helpers::AssetTagHelper

module LocationMapper
  unless included_modules.include? LocationMapper
    def self.included(klass)
      case klass.name
      when 'BasketsController'
        klass.send :before_filter, :prepare_google_map_without_instantiation, :only => ['choose_type']
      else
        klass.send :before_filter, :prepare_google_map, :only => ['show', 'new', 'create', 'edit', 'update']
      end
      klass.helper LocationMapperHelpers
    end

    private

    def prepare_google_map_without_instantiation
      prepare_google_map
      @do_not_load_google_maps_on_page_load = true
    end

    def prepare_google_map
      # we dont need the google map code on the topic type chooser page so turn it off here
      if params[:controller] == 'topics' && params[:action] == 'new' && (params[:topic].blank? || params[:topic][:topic_type_id].blank?)
        @using_google_maps = false
      else
        @using_google_maps = true
      end
    end
  end
end

module LocationMapperHelpers
  def load_google_map_api
    gma_config = File.join(RAILS_ROOT, 'config/google_map_api.yml')
    if @using_google_maps && File.exists?(gma_config)
      gma_config = YAML.load(IO.read(gma_config))
      # This works, but rails tries to add a .js on the end, which invalidated the api key, so we add the format= to hackishly fix this
      javascript_include_tag("http://www.google.com/jsapi?key=#{gma_config[:google_map_api][:api_key]}&amp;format=") +
      javascript_tag("
        // set the nessesary global vars used later on
        var map;
        var marker;
        var default_latitude = #{!@current_coords.nil? ? @current_coords.split(',')[0] : gma_config[:google_map_api][:default_latitude]};
        var default_longitude = #{!@current_coords.nil? ? @current_coords.split(',')[1] : gma_config[:google_map_api][:default_longitude]};
        var default_zoom_lvl = #{!@current_zoom_lvl.nil? ? @current_zoom_lvl : gma_config[:google_map_api][:default_zoom_lvl]};

        // this initiates the Google Map API (version 2)
        google.load('maps', '2', {'other_params':'sensor=true'});

        // the function run when the page finishes loading, to initiate the google map
        function initialize_google_map() {
          // make sure we don't do any google map code unless the browser supports it
          if (!google.maps.BrowserIsCompatible()) { alert('Google Maps is not compatible with this browser. Try using Firefox 3, Internet Explorer 7, or Safari  3'); return; }
          // check the google map div is present on the page before continuing
          if (!$('google_map_div')) { alert('You are trying to run google map api without a google map div present. Debug this!'); return; }
          // initialize the google map
          map = new google.maps.Map2($('google_map_div'));
          // center the map on the default latitude, longitude and zoom level (comes from either params, the item being edited, or config)
          map.setCenter(new google.maps.LatLng(default_latitude, default_longitude), default_zoom_lvl);
          // add the small controls in the top left of the map (for moving and zooming)
          map.addControl(new google.maps.SmallMapControl());
          // bind a search control to the map except on item show pages
          #{params[:action] != 'show' ? 'map.addControl(new google.maps.LocalSearch({
                suppressInitialResultSelection : true
                }), new GControlPosition(G_ANCHOR_BOTTOM_RIGHT, new GSize(10,25)));' : ''}
          // If the current coords arn't empty (i.e. form submitted or editing item), place a marker at that location
          // If empty, don't add one (new item for example wont need one until the map is clicked)
          #{!@current_coords.nil? ? 'remove_all_markers_and_add_one_at(default_latitude, default_longitude, false);' : ''}
          // the code from this point only executes on new/edit pages, not the show pages
          if ($('google_map_coords_value') && $('google_map_zoom_value')) {
            // make the debugging fields readOnly (eventually these might be disabled and hidden)
            $('google_map_coords_value').readOnly = true;
            $('google_map_zoom_value').readOnly = true;
            // this value should never be blank, so if it is, fill them with what we can
            if ($('google_map_coords_value').value == '') {
              $('google_map_coords_value').value = default_latitude + ',' + default_longitude;
            }
            // this value should never be blank, so if it is, fill them with what we can
            if ($('google_map_zoom_value').value == '') {
              $('google_map_zoom_value').value = default_zoom_lvl;
            }
            // when a user clicks the map, add a marker and update the coords and zoom level
            google.maps.Event.addListener(map, 'click', function(overlay, latlng) {
              // make sure that a latitude and longitude is passed in
              if (latlng) {
                // remove all existing markers and add one where the user clicked
                remove_all_markers_and_add_one_at(latlng.y, latlng.x, true);
                // toUrlValue(6) gives us a string like   -45.861836,127.398373  (which is the format we want)
                $('google_map_coords_value').value = latlng.toUrlValue(6);
                // the current maps zoom level
                $('google_map_zoom_value').value = map.getZoom();
              }
            });
            // when a user stops dragging/zooming, update the zoom level (not the coords, thats what the pinpoint is for)
            google.maps.Event.addListener(map, 'moveend', function() {
              $('google_map_zoom_value').value = map.getZoom();
            });
          }
        }

        // remove all existing markers and one at specified latitude and longitude
        function remove_all_markers_and_add_one_at(latitude, longitude, draggable) {
          // clears all overlays (info boxes, markers etc)
          map.clearOverlays();
          // create the marker (draggable is passed in as either true or false)
          marker = new GMarker(new GLatLng(latitude, longitude), {draggable: draggable});
          // add the marker to the map
          map.addOverlay(marker);
          // when a user stops dragging the marker, update the coords and zoom level
          google.maps.Event.addListener(marker, 'dragend', function() {
            // toUrlValue(6) gives us a string like   -45.861836,127.398373  (which is the format we want)
            $('google_map_coords_value').value = marker.getLatLng().toUrlValue(6);
            // the current maps zoom level
            $('google_map_zoom_value').value = map.getZoom();
          });
        }

        // when the page has finished loading, then initiate the google map
        #{@do_not_load_google_maps_on_page_load ? '// called later on this page' : 'google.setOnLoadCallback(initialize_google_map);'}
      ") +
      javascript_include_tag("http://www.google.com/uds/api?file=uds.js&amp;v=1.0&amp;key=#{gma_config[:google_map_api][:api_key]}") +
      javascript_include_tag("http://www.google.com/uds/solutions/localsearch/gmlocalsearch") +
      stylesheet_link_tag("http://www.google.com/uds/css/gsearch.css") +
      stylesheet_link_tag("http://www.google.com/uds/solutions/localsearch/gmlocalsearch.css")
    end
  end
end