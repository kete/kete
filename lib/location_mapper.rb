include ActionView::Helpers::JavaScriptHelper
include ActionView::Helpers::AssetTagHelper

module LocationMapper
  unless included_modules.include? LocationMapper
    def self.included(klass)
      case klass.name
      when 'BasketsController'
        klass.send :before_filter, :instantiate_google_map, :only => ['choose_type']
      else
        klass.send :before_filter, :instantiate_google_map, :only => ['show', 'new', 'create', 'edit', 'update']
      end
      klass.helper LocationMapperHelpers
    end

    private

    def instantiate_google_map
      @using_google_maps = true
    end
  end
end

module LocationMapperHelpers
  def load_google_map_api
    gma_config = File.join(RAILS_ROOT, 'config/google_map_api.yml')
    if @using_google_maps && File.exists?(gma_config)
      gma_config = YAML.load(IO.read(gma_config))
      javascript_include_tag("http://www.google.com/jsapi?key=#{gma_config[:google_map_api][:api_key]}&amp;format=") +
      javascript_tag("
        var default_latitude = #{!@current_coords.nil? ? @current_coords.split(',')[0] : gma_config[:google_map_api][:default_latitude]};
        var default_longitude = #{!@current_coords.nil? ? @current_coords.split(',')[1] : gma_config[:google_map_api][:default_longitude]};
        var default_zoom_lvl = #{!@current_zoom_lvl.nil? ? @current_zoom_lvl : gma_config[:google_map_api][:default_zoom_lvl]};
        google.load('maps', '2');
        function initialize_google_map() {
          // check all three divs are present on the page before continuing
          if (!$('google_map_div')) { return; }
          // initialize the google map
          var map = new google.maps.Map2($('google_map_div'));
          map.setCenter(new google.maps.LatLng(default_latitude, default_longitude), default_zoom_lvl);
          map.addControl(new google.maps.SmallMapControl());
          // disable the debugging fields (eventually these might be hidden)
          if ($('google_map_coords_value') && $('google_map_zoom_value')) {
            if ($('google_map_coords_value').value == '') {
              $('google_map_coords_value').value = default_latitude + ',' + default_longitude;
            }
            $('google_map_coords_value').readOnly = true;
            if ($('google_map_zoom_value').value == '') {
              $('google_map_zoom_value').value = default_zoom_lvl;
            }
            $('google_map_zoom_value').readOnly = true;
            // when a user clicks, update the coords and zoom level
            google.maps.Event.addListener(map, 'click', function(overlay, latlng) {
              if (latlng) {
                $('google_map_coords_value').value = latlng.toUrlValue(6);
                $('google_map_zoom_value').value = map.getZoom();
              }
            });
            // when a user stops dragging, update the coords and zoom level
            google.maps.Event.addListener(map, 'moveend', function() {
              $('google_map_coords_value').value = map.getCenter().toUrlValue(6);
              $('google_map_zoom_value').value = map.getZoom();
            });
          }
        }
        google.setOnLoadCallback(initialize_google_map);
      ")
    end
  end
end