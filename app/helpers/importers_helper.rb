module ImportersHelper
  def xml_type_js_observer
    javascript_tag("
      function display_applicable_import_fields() {
        var value = $('import_xml_type').value;

        // hide the xml_path_to_record text field if this type doesn't need it
        if ( value == 'simple_xml' ) {
          $('import_xml_path').show();
          $('import_xml_path_to_record').disabled = false;
        } else {
          $('import_xml_path_to_record').value = '';
          $('import_xml_path_to_record').disabled = true;
          $('import_xml_path').hide();
        }

        // hide the zoom_class choice if this type doesn't need it
        // hide the related_topic_type and extended_field_that_contains_record_identifier choices if this type doesn't need it
        // hide the related_records_field and record_identifier_field values if this type doesn't need it
        if ( value == 'excel_based' || value == 'dfc_xml' || value == 'simple_xml' ) {
          $('zoom_class').disabled = false;
          $('zoom_class').value = 'Topic';
          $('zoom').show();
          $('import_related_items').show();
          $('import_related_records').show();
          $('record_identifier_fields').show();
        } else {
          $('zoom_class').value = '';
          $('zoom_class').disabled = true;
          $('zoom').hide();
          $('import_related_items').hide();
          $('import_related_records').hide();
          $('record_identifier_fields').hide();
        }
      }

      $('import_xml_type').observe('change', function() { display_applicable_import_fields(); });
      display_applicable_import_fields();
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
          $('import_file_private').hide();
        } else {
          $('import_topic_type_id').value = '';
          $('import_topic_type_id').disabled = true;
          $('import_topic_type').hide();
          if ( value != 'WebLink' ) {
            $('import_file_private').show();
          } else {
            $('import_file_private').hide();
          }
        }
      });
    ")
  end

  def record_identifier_js_observer
    javascript_tag("
      $('zoom_class').observe('change', function() {
        zoom_class = $('zoom_class').value;
        new Ajax.Updater('import_extended_field_that_contains_record_identifier_select', '#{url_for(:action => 'fetch_applicable_extended_fields')}', {
          parameters: { id: 'extended_field_that_contains_record_identifier_id', zoom_class: zoom_class },
          onCreate: function() { $('extended_fields_spinner_for_extended_field_that_contains_record_identifier_id').show(); },
          onComplete: function() { $('extended_fields_spinner_for_extended_field_that_contains_record_identifier_id').hide(); }
        });
      });

      $('import_topic_type_id').observe('change', function() {
        topic_type_id = $('import_topic_type_id').value;
        new Ajax.Updater('import_extended_field_that_contains_record_identifier_select', '#{url_for(:action => 'fetch_applicable_extended_fields')}', {
          parameters: { id: 'extended_field_that_contains_record_identifier_id', zoom_class: 'Topic', topic_type_id: topic_type_id },
          onCreate: function() { $('extended_fields_spinner_for_extended_field_that_contains_record_identifier_id').show(); },
          onComplete: function() { $('extended_fields_spinner_for_extended_field_that_contains_record_identifier_id').hide(); }
        });
      });
    ")
  end

  def related_topics_js_observer
    javascript_tag("
      $('import_has_related_items_in_data').observe('change', function() {
        if ($('import_has_related_items_in_data').checked) {
          $('import_related_items_fields').show();
        } else {
          $('import_related_items_fields').hide();
        }
      });

      $('import_related_topic_type_id').observe('change', function() {
        new Ajax.Updater('import_extended_field_that_contains_related_topics_reference_select', '#{url_for(:action => 'fetch_applicable_extended_fields')}', {
          parameters: { id: 'extended_field_that_contains_related_topics_reference_id', zoom_class: 'Topic', topic_type_id: $('import_related_topic_type_id').value },
          onCreate: function() { $('extended_fields_spinner_for_extended_field_that_contains_related_topics_reference_id').show(); },
          onComplete: function() { $('extended_fields_spinner_for_extended_field_that_contains_related_topics_reference_id').hide(); }
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
