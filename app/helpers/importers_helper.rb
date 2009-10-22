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
          // hide the zoom_class choice if this type doesn't need it
          if ( value == 'excel_based' || value == 'dfc_xml' ) {
            $('zoom_class').disabled = false;
            $('zoom_class').value = 'Topic';
            $('zoom').show();
          } else {
            $('zoom_class').value = '';
            $('zoom_class').disabled = true;
            $('zoom').hide();
          }
          // hide the related_topic_type and record_identifier_extended_field choices if this type doesn't need it
          if ( value == 'dfc_xml' ) {
            $('import_related_topic_type').show();
            $('import_record_identifier_extended_field').show();
          } else {
            $('import_related_topic_type').hide();
            $('import_record_identifier_extended_field').hide();
          }
        });
      ")
  end

  def zoom_class_js_observer
    javascript_tag("
        $('zoom_class').observe('change', function() {
          value = $('zoom_class').value;
          // hide the topic_type field if this class doesn't need it
          if ( value == 'Topic' ) {
            $('import_topic_type').show();
            $('import_topic_type_id').disabled = false;
          } else {
            $('import_topic_type_id').value = '';
            $('import_topic_type_id').disabled = true;
            $('import_topic_type').hide();
          }
        });
      ")
  end

  def related_topic_type_js_observer
    javascript_tag("
      $('import_related_topic_type_id').observe('change', function() {
        new Ajax.Updater('import_record_identifier_extended_field_select', '#{url_for(:action => 'fetch_applicable_extended_fields')}', {
          parameters: { topic_type_id: $('import_related_topic_type_id').value },
          onCreate: function() {
            $('extended_fields_spinner').show();
          },
          onComplete: function() {
            $('extended_fields_spinner').hide();
          }
        });
      });
    ")
  end

  # dynamically define query methods for our attribute specs
  def self.define_options_method_for(constant_name)
    method_name = constant_name.downcase + '_as_options'

    # create the template code
    code = Proc.new {
      options = Array.new
      constant_name.constantize.each do |item_class_name|
        selected = (@zoom_class_name == item_class_name) ? " selected='selected'" : ''
        options << "<option value='#{item_class_name}'#{selected}>#{zoom_class_plural_humanize(item_class_name)}</option>"
      end
      options.join('')
    }

    define_method(method_name, &code)
  end

  ["ATTACHABLE_CLASSES", "ITEM_CLASSES"].each { |constant_name| define_options_method_for(constant_name) }

end
