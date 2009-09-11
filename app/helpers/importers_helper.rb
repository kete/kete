module ImportersHelper
  def xml_type_js_observer
    javascript_tag("
        $('import_xml_type').observe('change', function() {
          value = $('import_xml_type').value;
          // hide the xml_path_to_record text field if this type doesn't need it
          if ( value == 'simple_topic' ) {
            $('import_xml_path').show();
            $('import_xml_path_to_record').disabled = false;
          } else {
            $('import_xml_path_to_record').value = '';
            $('import_xml_path_to_record').disabled = true;
            $('import_xml_path').hide();
          }
          // hide the topic_type_id if this type doesn't need it
          if ( value == 'past_perfect4' || value == 'fmpdsoresult_no_images' || value == 'simple_topic') {
            $('import_topic_type_id').disabled = false;
            $('import_topic_type').show();
          } else {
            $('import_topic_type_id').value = '';
            $('import_topic_type_id').disabled = true;
            $('import_topic_type').hide();
          }
          // hide the zoom_class choice if this type doesn't need it
          if ( value == 'excel_based') {
            $('zoom_class').disabled = false;
            $('zoom_class').value = 'Topic';
            $('zoom').show();
          } else {
            $('zoom_class').value = '';
            $('zoom_class').disabled = true;
            $('zoom').hide();
          }
        });
      ")
  end
  
  def attachable_classes_as_options
    options = Array.new
    ATTACHABLE_CLASSES.each do |item_class_name|
      selected = (@zoom_class_name == item_class_name) ? " selected='selected'" : ''
      options << "<option value='#{item_class_name}'#{selected}>#{zoom_class_plural_humanize(item_class_name)}</option>"
    end
    options.join('')
  end

end
