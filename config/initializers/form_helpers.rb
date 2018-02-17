class FormHelper < ActionView::Helpers::FormBuilder
  helpers = field_helpers +
            %w{date_select datetime_select time_select} +
            %w{collection_select select country_select time_zone_select} -
            %w{hidden_field label fields_for submit} # Don't decorate these

  helpers.each do |name|
    define_method(name) do |field, *args|
      options = args.extract_options!

      required = options.delete(:required) || false
      classes = options.delete(:label_class) || ''
      classes = "required #{classes}" if required
      required_icon = required ? ' <em>*</em>' : ''

      label = ''
      label = label(field, options.delete(:label) + required_icon, class: classes) if options[:label].present?

      field_example = options[:example].nil? ? '' : @template.content_tag(:div, options.delete(:example), class: 'form-example')

      fields = ''
      if name == 'radio_button' && args.first.is_a?(Array) # a set of radio buttons
        fields += "<ul class='option-list'>\n"
        args.first.each do |radio|
          label_text, radio_value = radio[0], radio[1]
          label_for, note = radio[2].delete(:label_for), radio[2].delete(:note)
          radio_field = super(field, radio_value, options.merge(radio[2]))
          radio_label = label(field, label_text, for: label_for)
          fields += @template.content_tag(:li, "\n#{radio_field}\n#{radio_label} #{note unless note.blank?}\n") + "\n"
        end
        fields += "</ul>\n"
      else
        fields += super
      end

      @template.content_tag(:div, "\n#{label}\n#{fields}\n#{field_example}", class: 'form-element') + "\n"
    end
  end
end
