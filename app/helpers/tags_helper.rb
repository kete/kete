module TagsHelper
  def link_to_tagged_in_basket(options = {})
    link_to h(options[:name]),
    { :controller => 'search', :action => 'all',
      :tag => options[:id],
      :trailing_slash => true,
      :controller_name_for_zoom_class => zoom_class_controller(options[:zoom_class]) }
  end

  def toggle_in_reverse_field_js_helper
    javascript_tag "
    function toggleDisabledSortDirection(event) {
      var element = Event.element(event);
      if ( element.options[element.selectedIndex].value == \"random\" ) {
        $('direction_field').hide()
      } else {
        $('direction_field').show()
      }
    }

    $('tag_order').observe('change', toggleDisabledSortDirection);"
  end
end
