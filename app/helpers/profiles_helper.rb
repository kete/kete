# this is mainly to do with setting up our custom active scaffold stuff
module ProfilesHelper
  # Override for ActiveScaffold extended field controller edit view
  # Refer to http://activescaffold.com/docs/form-overrides for details

  def rules_form_column(record, input_name)
    html = String.new
    if record.new_record?
      html = "<div id=\"rules_forms\" style=\"display: inline-block; margin-left: 2em;\">"
      type_options = [['--choose included form fields--', 'none']] + Profile.type_options
      # we start with a select for type options for each form
      Basket::FORMS_OPTIONS.each do |form_option|
        form_type = form_option[1]
        html += "<div id=\"#{form_type}_section\">"
        html += "<label for=\"#{form_type}\">#{form_option[0]}</label>"
        html += select(:record, "rules[#{form_type}]", type_options, {}, :name => input_name ) + "\n" +
          javascript_tag("
        $('record_rules[#{form_type}]').observe('change', function() {
          value = $('record_rules[#{form_type}]').value;
          // show the allow user choices section when ftype supports it
          if ( value == 'some' ) {
            $('#{form_type}').show();
          } else {
            $('form_type').hide();
          }
        });
      ")
        html += "<div id=\"#{form_type}\">"
        html += edit_form
        html += "</div>"
        html += "</div>"
      end
      html += "</div>"

    else
      html = "#{record.profile_rules} (cannot be changed)"
    end
    html
  end

  def edit_form
    @basket = Basket.new
    html = render_to_string(:template => '/baskets/new',
                            :layout => false)
  end
end
