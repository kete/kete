# this is mainly to do with setting up our custom active scaffold stuff
module ProfilesHelper
  # Override for ActiveScaffold rules column for basket profiles
  # Refer to http://activescaffold.com/docs/form-overrides for details
  # If a new record, for each form type, create a dropdown with the rule types
  # when the rule type is 'some', dropdown the rules selection settings
  def rules_form_column(record, input_name)
    html = String.new
    if record.new_record?
      html = '<div id="rules_forms" style="display: inline-block; margin-left: 2em;">'
      type_options = [[t('profiles_helper.rules_form_column.choose_included_fields'), '']] + Profile.type_options
      # we start with a select for type options for each form
      Basket.forms_options.each do |form_option|
        form_type = form_option[1]
        html += "<div id=\"#{form_type}_section\">"
        html += "<label for=\"#{form_type}\">#{form_option[0]}</label>"
        html += select_tag("#{input_name}[#{form_type}][rule_type]",
                           options_for_select(type_options, current_rule_for(form_type)),
                           id: "record_rules_#{form_type}_rule_type")
        html += "<div id=\"record_rules_#{form_type}_form\"#{" style=\"display:none;\"" if current_rule_for(form_type) != 'some'}>"
        html += fetch_form_for(form_type, input_name)
        html += '</div>'
        html += '</div>'
      end
      html += '</div>'

    else
      html = record.rules
      html += "<br /><strong>#{t('profiles_helper.rules_form_column.cannot_be_changed')}</strong>"
    end
    html
  end

  # Get any submitted rule types for form_type incase of failed validations
  # TODO Convert this to use Rails 2.3 try() method when available
  def current_rule_for(form_type)
    ; params[:record][:rules][form_type.to_sym][:rule_type]; rescue; ''; 
  end

  # Check whether this field was allowed during the submitted form incase of fails validations
  # TODO Convert this to use Rails 2.3 try() method when available
  def allowed_value?(field)
    ; params[:record][:rules][@rule_locals[:form_type].to_sym][:allowed].include?(field); rescue; false; 
  end

  # Get the current value for a field incase of failed validations
  # TODO Convert this to use Rails 2.3 try() method when available
  def current_value_for(field)
    ; params[:record][:rules][@rule_locals[:form_type].to_sym][:values][field.to_sym]; rescue; ''; 
  end

  # Get the form for the rules column override method above
  # sets some vars used in the form so we dont have to have unnessecary duplication
  # The render_to_string method is made public and a helper in the profiles_controller
  def fetch_form_for(form_type, input_name)
    @rule_locals = { form_type: form_type,
                     input_name: input_name,
                     allowed_field_name: "#{input_name}[#{form_type}][allowed][]",
                     values_field_prefix: "#{input_name}[#{form_type}][values]",
                     field_id_prefix: "record_rules_#{form_type}" }
    render_to_string(partial: "profiles/#{form_type}")
  end

  # The allowed check box used to permit users to edit a form section
  # When called, adds the field name to profile_sections instance var
  # generates a checkbox with appropriate id and name, and adds an
  # section collapse/expand arrow underneath it
  def rules_allowed_check_box(name)
    @profile_sections ||= Array.new
    @profile_sections << name

    content = check_box_tag(@rule_locals[:allowed_field_name], name, allowed_value?(name),
                            id: rules_allowed_id(name))
    content += '<br />' + image_tag('icon_results_next_off.gif',
                                    id: "#{rules_allowed_id(name)}_expander",
                                    class: 'expand_policy',
                                    alt: t('profiles_helper.rules_allowed_check_box.expand_policy'),
                                    title: t('profiles_helper.rules_allowed_check_box.expand_policy'))
    content_tag('div', content, class: 'allowed_check_box')
  end

  # The id of the allowed checkbox. We have a method
  # for it because the id is needed elsewhere
  def rules_allowed_id(name)
    "#{@rule_locals[:field_id_prefix]}_allowed_#{name}"
  end

  # The id of the rules label. As above, we have a method
  # for it because the id is needed elsewhere
  def rules_label_id(name, value = nil)
    value ? "#{@rule_locals[:field_id_prefix]}_values_#{name}_#{value}" \
          : "#{@rule_locals[:field_id_prefix]}_values_#{name}"
  end

  # A text field tag. Wraps it in form-element div,
  # with label, and appropriate id and name
  def rules_text_field_tag(name, label)
    '<div class="form-element">' +
      content_tag('label', label, for: rules_label_id(name), style: 'width: 100%;') +
      '<div style="clear: left">' +
      text_field_tag("#{@rule_locals[:values_field_prefix]}[#{name}]", current_value_for(name),
                     id: "#{@rule_locals[:field_id_prefix]}_values_#{name}", tabindex: '1') +
      '</div>' +
      '</div>'
  end

  # A text area tag. Wraps it in form-element div,
  # with label, and appropriate id and name
  def rules_text_area_tag(name, label = nil, class_name = 'tinymce')
    '<div class="form-element">' +
      (label ? content_tag('label', label, for: rules_label_id(name), class: 'inline') : '') +
      text_area_tag("#{@rule_locals[:values_field_prefix]}[#{name}]", current_value_for(name),
                    rows: 7, cols: 30, class: class_name) +
      '</div>'
  end

  # A select tag. Wraps it in form-element div,
  # with label, and appropriate id and name
  def rules_select_tag(name, options, label = nil)
    '<div class="form-element">' +
      (label ? content_tag('label', label, for: rules_label_id(name), style: 'width: 100%;') : '') +
      '<div style="clear: left">' +
      select_tag("#{@rule_locals[:values_field_prefix]}[#{name}]", options,
                 id: "#{@rule_locals[:field_id_prefix]}_values_#{name}", tabindex: '1') +
      '</div>' +
      '</div>'
  end

  # A radio button tag. Wraps it in form-element div,
  # with label, and appropriate id and name
  def rules_radio_button_tag(name, value, label)
    '<div class="form-element">' +
      radio_button_tag("#{@rule_locals[:values_field_prefix]}[#{name}]", value, (current_value_for(name) == value),
                       id: "#{@rule_locals[:field_id_prefix]}_values_#{name}_#{value}", tabindex: '1') +
      content_tag('label', label, for: rules_label_id(name, value), class: 'inline') +
      '</div>'
  end

  # A check box tag. Wraps it in form-element div,
  # with label, and appropriate id and name
  def rules_check_box_tag(name, value, label, is_array = false)
    '<div class="form-element">' +
      check_box_tag("#{@rule_locals[:values_field_prefix]}[#{name}]#{'[]' if is_array}", value,
                    (is_array && current_value_for(name).is_a?(Array) ? current_value_for(name).include?(value) : current_value_for(name) == value),
                    id: "#{@rule_locals[:field_id_prefix]}_values_#{name}#{"_#{value.underscore.downcase}" if is_array}", tabindex: '1') +
      content_tag('label', label, for: "#{rules_label_id(name)}#{"_#{value.underscore.downcase}" if is_array}", class: 'inline') +
      '</div>'
  end

  # The fieldset that wraps around the above field tag methods
  # The id is important because its used for collapsing/expandinf the section
  def rules_fieldset_tag(name)
    "<fieldset id='#{rules_label_id(name)}_fieldset'#{" style='display:none;'" unless allowed_value?(name)}>"
  end
end
