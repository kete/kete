module TagsHelper
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
