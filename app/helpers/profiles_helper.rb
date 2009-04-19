# this is mainly to do with setting up our custom active scaffold stuff
module ProfilesHelper
  # Override for ActiveScaffold extended field controller edit view
  # Refer to http://activescaffold.com/docs/form-overrides for details

  def rules_form_column(record, input_name)
    html = String.new
    if record.new_record?
      html = "<div id=\"rules_forms\" style=\"display: inline-block; margin-left: 2em;\">"
      type_options = [['--choose included form fields--', '']] + Profile.type_options
      # we start with a select for type options for each form
      Basket::FORMS_OPTIONS.each do |form_option|
        form_type = form_option[1]
        html += "<div id=\"#{form_type}_section\">"
        html += "<label for=\"#{form_type}\">#{form_option[0]}</label>"
        html += select_tag("#{input_name}[#{form_type}][rule_type]",
                           options_for_select(type_options, current_rule_for(form_type)),
                           :id => "record_rules_#{form_type}_rule_type")
        html += javascript_tag("
          $('record_rules_#{form_type}_rule_type').observe('change', function() {
            value = $('record_rules_#{form_type}_rule_type').value;
            // show the allow user choices section when ftype supports it
            if ( value == 'some' ) {
              $('record_rules_#{form_type}_form').show();
            } else {
              $('record_rules_#{form_type}_form').hide();
            }
          });
        ")
        html += "<div id=\"record_rules_#{form_type}_form\"#{" style=\"display:none;\"" if current_rule_for(form_type) != 'some'}>"
        html += fetch_form_for(form_type, input_name)
        html += "</div>"
        html += "</div>"
      end
      html += "</div>"

    else
      html = record.rules
      html += "<br /><strong>(cannot be changed)</strong>"
    end
    html
  end

  # TODO Convert this to use Rails 2.3 try() method when available
  def current_rule_for(form_type)
    begin; params[:record][:rules][form_type.to_sym][:rule_type]; rescue; ''; end
  end

  # TODO Convert this to use Rails 2.3 try() method when available
  def allowed_value?(field)
    begin; params[:record][:rules][@rule_locals[:form_type].to_sym][:allowed].include?(field); rescue; false; end
  end

  # TODO Convert this to use Rails 2.3 try() method when available
  def current_value_for(field)
    begin; params[:record][:rules][@rule_locals[:form_type].to_sym][:values][field.to_sym]; rescue; ''; end
  end

  def fetch_form_for(form_type, input_name)
    @rule_locals = { :form_type => form_type,
                     :input_name => input_name,
                     :allowed_field_name => "#{input_name}[#{form_type}][allowed][]",
                     :values_field_prefix => "#{input_name}[#{form_type}][values]",
                     :field_id_prefix => "record_rules_#{form_type}" }
    return 'nothing to see yet' unless form_type == 'edit'
    render_to_string(:partial => "profiles/#{form_type}")
  end

  def rules_allowed_check_box(name)
    content_tag('div', check_box_tag(@rule_locals[:allowed_field_name], name, allowed_value?(name),
                  :id => rules_allowed_id(name)), :class => 'allowed_check_box')
  end

  def rules_allowed_id(name)
    "#{@rule_locals[:field_id_prefix]}_allowed_#{name}"
  end

  def rules_label_id(name, value=nil)
    value ? "#{@rule_locals[:field_id_prefix]}_values_#{name}_#{value}" \
          : "#{@rule_locals[:field_id_prefix]}_values_#{name}"
  end

  def rules_text_field_tag(name)
    text_field_tag("#{@rule_locals[:values_field_prefix]}[#{name}]", current_value_for(name),
                   :id => "#{@rule_locals[:field_id_prefix]}_values_#{name}", :tabindex => '1')
  end

  def rules_select_tag(name, options)
    select_tag("#{@rule_locals[:values_field_prefix]}[#{name}]", options,
               :id => "#{@rule_locals[:field_id_prefix]}_values_#{name}", :tabindex => '1')
  end

  def rules_radio_button_tag(name, value)
    radio_button_tag("#{@rule_locals[:values_field_prefix]}[#{name}]", value, (current_value_for(name) == value),
                     :id => "#{@rule_locals[:field_id_prefix]}_values_#{name}_#{value}", :tabindex => '1')
  end

  def rules_check_box_tag(name, value, is_array=false)
    check_box_tag("#{@rule_locals[:values_field_prefix]}[#{name}]#{'[]' if is_array}", value,
                  (is_array && current_value_for(name).is_a?(Array) ? current_value_for(name).include?(value) : current_value_for(name) == value),
                  :id => "#{@rule_locals[:field_id_prefix]}_values_#{name}#{"_#{value.underscore.downcase}" if is_array}", :tabindex => '1')
  end

end
