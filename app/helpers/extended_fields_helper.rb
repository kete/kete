# frozen_string_literal: true

module ExtendedFieldsHelper
  # Override for ActiveScaffold extended field controller edit view
  # Refer to http://activescaffold.com/docs/form-overrides for details

  def topic_type_form_column(record, input_name)
    topic_types = TopicType.find(1).full_set
    select = topic_type_select_with_indent(
      'record', 'topic_type', topic_types, :id, :name, nil,
      { class: 'select', tabindex: '1' }
    )
    content_tag('div', select, { id: "hidden_choices_topic_type_select_#{record.id}", style: 'display:none;' })
  end

  def circa_form_column(record, input_name)
    checkbox = check_box('record', 'circa', { checked: (!record.new_record? && record.circa?) })
    content_tag(
      'div', checkbox, id: "hidden_choices_circa_#{record.id}",
                       style: record.new_record? || record.ftype != 'year' ? 'display:none;' : ''
    )
  end

  # Using YUI TreeView
  def pseudo_choices_form_column(record, input_name)
    top_level = Choice.find_top_level
    id = 'tree_' + record.id.to_s

    # Containing DIV for theme
    '<div class="yui-skin-sam" style="float: left" id="hidden_choices_select_' + record.id.to_s + '">' +
      # Expand all and collapse all links
      content_tag('p', link_to_function(t('extended_fields_helper.pseudo_choices_form_column.expand_all'), '', id: "#{id}_expand") + ' | ' + link_to_function(t('extended_fields_helper.pseudo_choices_form_column.collapse_all'), '', id: "#{id}_collapse")) +
      # Actual XHTML list that is shown in the case JS fails or is not supported
      '<div id="choice_selection_' + record.id.to_s + '"><ul>' +
      top_level.inject('') do |m, choice|
        m = m + build_ul_for_choice(choice, record)
      end +
      '</ul></div>' +
      '<div id="allow_user_additions">' +
      "#{t('extended_fields_helper.pseudo_choices_form_column.allow_user_choices')} #{t('extended_fields_helper.pseudo_choices_form_column.allow_user_choices_yes')} " + radio_button_tag('record[user_choice_addition]', 1, record.user_choice_addition?) + " #{t('extended_fields_helper.pseudo_choices_form_column.allow_user_choices_no')} " + radio_button_tag('record[user_choice_addition]', 0, !record.user_choice_addition?) +
      '</div>' +
      '<div id="link_choice_values">' +
      "#{t('extended_fields_helper.pseudo_choices_form_column.link_choice_values')} #{t('extended_fields_helper.pseudo_choices_form_column.link_choice_values_yes')} " + radio_button_tag('record[link_choice_values]', 1, !record.dont_link_choice_values?) + " #{t('extended_fields_helper.pseudo_choices_form_column.link_choice_values_no')} " + radio_button_tag('record[link_choice_values]', 0, record.dont_link_choice_values?) +
      '</div>' +
      '</div>'
  end

  # Build hierarchical UL, LI structure for a choice and recurse through children elements
  def build_ul_for_choice(choice, record)
    content_tag('li', check_box_tag('record[pseudo_choices][]', choice.id.to_s, record.choices.member?(choice)) + ' ' + choice.label + build_ul_for_children_of(choice, record))
  end

  def user_choice_addition_form_column(record, input_name)
    ''
  end

  def link_choice_values_form_column(record, input_name)
    ''
  end

  # Build hierarchicial UL, LI for children elements of a choice
  def build_ul_for_children_of(choice, record)
    if choice.children.empty?
      ''
    else
      '<ul>' +
        choice.children.inject('') do |m, child|
          m = m + build_ul_for_choice(child, record)
        end +
        '</ul>'
    end
  end

  # More ActiveScaffold overloading..

  # Same as above, but for ftype.
  # We are not being strict about which ftypes are allowed and which are not.
  def ftype_form_column(record, input_name)
    options_for_select = [
      [t('extended_fields_helper.ftype_form_column.check_box'), 'checkbox'],
      [t('extended_fields_helper.ftype_form_column.radio_button'), 'radio'],
      [t('extended_fields_helper.ftype_form_column.date'), 'date'],
      [t('extended_fields_helper.ftype_form_column.year'), 'year'],
      [t('extended_fields_helper.ftype_form_column.text'), 'text'],
      [t('extended_fields_helper.ftype_form_column.text_box'), 'textarea'],
      [t('extended_fields_helper.ftype_form_column.choices_auto_complete'), 'autocomplete'],
      [t('extended_fields_helper.ftype_form_column.choices_drop_down'), 'choice'],
      [t('extended_fields_helper.ftype_form_column.choices_topic_type'), 'topic_type']
    ]

    if SystemSetting.enable_maps?
      options_for_select << [t('extended_fields_helper.ftype_form_column.location_map'), 'map']
      options_for_select << [t('extended_fields_helper.ftype_form_column.location_map_address'), 'map_address']
    end

    if record.new_record?
      select(:record, :ftype, options_for_select, {}, name: input_name)
    else
      "#{record.ftype} #{t('extended_fields_helper.ftype_form_column.cannot_be_changed')}"
    end
  end

  # Ensure that label value cannot be changed (attr_readonly)
  def label_form_column(record, input_name)
    if record.new_record?
      text_field(:record, :label, class: 'label-input text-input', id: 'record_label_', size: '20', autocomplete: 'off')
    else
      "#{record.label} #{t('extended_fields_helper.label_form_column.cannot_be_changed')}"
    end
  end

  # Ensure that multiple value cannot be changed (attr_readonly)
  def multiple_form_column(record, input_name)
    if record.new_record?
      select(:record, :multiple, [['True', true], ['False', false]])
    else
      "#{record.multiple.to_s.capitalize} #{t('extended_fields_helper.multiple_form_column.cannot_be_changed')}"
    end
  end

  # Same as above, but for choice hierarchy
  def parent_form_column(record, input_name)
    if record.new_record?

      # Due to a limitation on better-nested-set, you cannot move_to any node unless the node you're
      # moving has already been saved. The intention here is that hierarchical manipulation of choices
      # will be done from the parent side.
      t('extended_fields_helper.parent_form_column.need_choice_for_parent')
    else

      select(
        :record, :parent_id,
        Choice.all.reject { |c| c.id == record.id }.map { |c| [c.label, c.id] },
        { select: record.parent_id }, name: input_name
      )
    end
  end

  # Same as above, but for choice children selection
  def children_form_column(record, input_name)
    if record.new_record?

      # Due to a limitation on better-nested-set, you cannot move_to any node unless the node you're
      # moving has already been saved. The intention here is that hierarchical manipulation of choices
      # will be done from the parent side.
      t('extended_fields_helper.children_form_column.need_choice_for_children')
    else

      currently_selected =
        record.children.map do |choice|
          check_box_tag('record[children][]', choice.id, true) + ' ' + choice.label
        end

      candidates =
        Choice.root.children.reject { |c| record.parent == c || record == c }.map do |choice|
          check_box_tag('record[children][]', choice.id, false) + ' ' + choice.label
        end

      output = content_tag('h6', t('extended_fields_helper.children_form_column.existing_sub_choices'))
      output << '<ul>' + currently_selected.inject('') do |memo, choice|
        memo = memo + content_tag('li', choice)
      end + '</ul>'

      output << content_tag('h6', t('extended_fields_helper.children_form_column.add_more_sub_choices'))
      output << '<ul>' + candidates.inject('') do |memo, choice|
        memo = memo + content_tag('li', choice)
      end + '</ul>'

      content_tag('div', output, style: 'float: left')
    end
  end

  # Ensure children of a choice are displayed in a reasonable manner
  def children_column(record)
    record.children.map { |c| c.label }.join(', ')
  end

  # Generates label and editor for extended field
  # Also adds additional extended field control for multiples
  # Receives one of Topic#topic_type.topic_type_to_field_mapping (TopicTypeToFieldMapping),
  # or ContentType.content_type_to_field_mapping (ContentTypeToFieldMapping)
  # Followed by an item type for params (i.e. 'topic' or 'user'
  # (params[:#{item_type_for_params}]))
  def extended_field_control(mapping, item_type_for_params)
    @item_type_for_params = item_type_for_params
    extended_field = mapping.extended_field

    # Generate and Id for the field (important for multiples
    generate_id_for_extended_field(extended_field)

    # Construct the basic control
    # TODO: Where does required argument come from?
    base = extended_field_label(extended_field, required) + extended_field_editor(extended_field)

    # Also display a control to add further field instances if necessary
    # TODO: Ensure the additional field control is only shown after the last multiple in a sequence
    extended_field.multiple? ? base + additional_extended_field_control(extended_field) : base
  end

  # Build a generic editor for the extended field
  def extended_field_editor(extended_field, value = nil, options = HashWithIndifferentAccess.new)
    @field_multiple_id = options[:multiple] || 1

    # Compile options for text_field_tag
    tag_options = {
      id: id_for_extended_field(extended_field),
      tabindex: 1
    }

    # Compile tag XHTML name
    name = name_for_extended_field(extended_field)

    builder = "extended_field_#{extended_field.ftype}_editor".to_sym
    if %w(choice autocomplete).member?(extended_field.ftype)
      send(:extended_field_choice_editor, name, value, tag_options, extended_field)
    elsif extended_field.ftype == 'topic_type'
      send(:extended_field_topic_type_editor, name, value, tag_options, extended_field)
    elsif extended_field.ftype == 'year'
      send(:extended_field_year_editor, name, value, tag_options, extended_field)
    elsif %w(map map_address).member?(extended_field.ftype)
      send(builder, name, value, extended_field, tag_options)
    elsif respond_to?(builder)
      send(builder, name, value, tag_options)
    else
      send(:extended_field_text_editor, name, value, tag_options)
    end
  end

  def extended_field_checkbox_editor(name, value, options)
    check_box_tag(name, 'yes', (value.to_s =~ /^(Yes|yes)$/), options)
  end

  def extended_field_radio_editor(name, existing_value, options)
    default_choices = [[t('extended_fields_helper.extended_field_radio_editor.yes'), 'yes'], [t('extended_fields_helper.extended_field_radio_editor.no'), 'no'], [t('extended_fields_helper.extended_field_radio_editor.no_value'), '']]

    # In the future we might allow radio buttons to be used for selecting choices
    # choices = extended_field.choices.empty? ? default_choices : extended_field.choices.find_top_level.map { |c| [c.label, c.value] }

    html = default_choices.map do |label, value|
      radio_button_tag(name, value, existing_value.to_s == value) + ' ' + label
    end.join("<br />\n")

    content_tag('div', html, 'class' => 'extended_field_radio_button_collection')
  end

  def extended_field_date_editor(name, value, options)
    extended_field_text_editor(name, value, options)
  end

  def extended_field_text_editor(name, value, options)
    text_field_tag(name, value, options)
  end

  def extended_field_textarea_editor(name, value, options)
    text_area_tag(name, value, options.merge(rows: 5, class: 'extended_field_textarea'))
  end

  def extended_field_choice_editor(name, value, options, extended_field)
    if value.is_a?(Array)
      value =
        value.collect do |v|
          if v.is_a?(Hash) && v['value']
            v = v['value']
          else
            v
          end
        end
    else
      value = value['value'] if value.is_a?(Hash) && value['value']
    end

    # Provide an appropriate selection interface..
    partial = extended_field.ftype == 'choice' ? 'choice_select_editor' : 'choice_autocomplete_editor'

    # Generate the choices we need to populate the SELECT or autocomplete.
    choices = extended_field.choices.find_top_level

    # If the top level is empty, find lower level tags to display
    choices = choices.blank? ? extended_field.choices.reject { |c| extended_field.choices.member?(c.parent) } : choices

    render partial: 'extended_fields/' + partial, locals: {
      name: name,
      value: value,
      options: options,
      extended_field: extended_field,
      choices: choices,
      # The default level is 1.. is this increased by subsequent renderings in ExtendedFieldsController.
      level: 1
    }
  end

  def extended_field_choice_select_editor(name, value, options, extended_field, choices, level = 1)
    # Build OPTION tags
    if choices.size > 0
      option_tags = options_for_select(
        [["- choose #{"sub-" if level > 1}#{display_label_for(extended_field).singularize.downcase} -", '']] +
                                               choices.map { |c| [c.label, c.value] }, value
      )
    else
      option_tags = options_for_select([["- no #{"sub-" if level > 1}#{display_label_for(extended_field).singularize.downcase} -", '']])
    end

    default_options = {
      id: "#{id_for_extended_field(extended_field)}_level_#{level}_preset",
      class: "#{id_for_extended_field(extended_field)}_choice_dropdown extended_field_choice_dropdown",
      tabindex: 1,
      onchange: remote_function(
        url: { controller: 'extended_fields', action: 'fetch_subchoices', for_level: level },
        with: "'value='+escape(Form.Element.getValue(this))+'&options[name]=#{name}&options[value]=#{value}&options[extended_field_id]=#{extended_field.id}&item_type_for_params=#{@item_type_for_params}&field_multiple_id=#{@field_multiple_id}&editor=select'",
        before: "Element.show('#{id_for_extended_field(extended_field)}_level_#{level}_spinner')",
        complete: "Element.hide('#{id_for_extended_field(extended_field)}_level_#{level}_spinner')"
      )
    }

    html = select_tag("#{name}[#{level}][preset]", option_tags, options.merge(default_options))
    html += "<img src='#{image_path('indicator.gif')}' width='16' height='16' alt='#{t('extended_fields_helper.extended_field_choice_select_editor.getting_choices')}' id='#{id_for_extended_field(extended_field)}_level_#{level}_spinner' style='display:none;' />"
    if extended_field.user_choice_addition?
      user_supplied_id = "#{id_for_extended_field(extended_field)}_level_#{level}_custom"
      html += " #{t(
        'extended_fields_helper.extended_field_choice_select_editor.suggest_a',
        field_name: display_label_for(extended_field).singularize.downcase
      )} "
      html += text_field_tag("#{name}[#{level}][custom]", nil, size: 10, id: user_supplied_id, class: "#{extended_field.label_for_params}_choice_custom", tabindex: 1)
    end
    html
  end

  def extended_field_choice_autocomplete_editor(name, value, options, extended_field, choices, level = 1)
    # Build a list of available choices
    choices = choices.map { |c| c.label }

    # Because we store the choice's value, not label, we need to find the label to be shown in the text field.
    # We also handle validation failures here by displaying the submitted value.
    selected_choice = Choice.matching(nil, value)
    value = selected_choice && !value.blank? ? selected_choice.label : nil

    remote_call = remote_function(
      url: { controller: 'extended_fields', action: 'fetch_subchoices', for_level: level },
      with: "'label='+escape(Form.Element.getValue(el))+'&options[name]=#{name}&options[value]=#{value}&options[extended_field_id]=#{extended_field.id}&item_type_for_params=#{@item_type_for_params}&field_multiple_id=#{@field_multiple_id}&editor=autocomplete'",
      before: "Element.show('#{id_for_extended_field(extended_field)}_#{level}_spinner')",
      complete: "Element.hide('#{id_for_extended_field(extended_field)}_#{level}_spinner')"
    )

    text_field_tag("#{name}[#{level}]", value, options.merge(id: "#{id_for_extended_field(extended_field)}_#{level}", autocomplete: 'off', tabindex: 1)) +
      "<img src='#{image_path('indicator.gif')}' width='16' height='16' alt='#{t('extended_fields_helper.extended_field_choice_autocomplete_editor.getting_choices')}' id='#{id_for_extended_field(extended_field)}_#{level}_spinner' style='display:none;' />" +
      tag('br') +
      content_tag(
        'div', nil,
        class: 'extended_field_autocomplete',
        id: id_for_extended_field(extended_field) + "_autocomplete_#{level}",
        style: 'display: none'
      ) +
      # We need to let our controller know that we're using autocomplete for this field.
      # We know the field we expect should be something like topic[extended_content][someonething]..
      hidden_field_tag("#{name.split(/\[/).first}[extended_content][#{name.scan(/\[([a-z_]*)\]/).flatten.at(1)}_from_autocomplete]", 'true', id: id_for_extended_field(extended_field) + '_from_autocomplete')
  end

  def extended_field_topic_type_editor(name, value, tag_options, extended_field)
    value = '' if value.blank?
    value = { 'label' => value[0], 'value' => value[1] } if value.is_a?(Array)
    value = "#{value['label']} (#{value['value']})" if value.is_a?(Hash) && value['value'] && value['label']

    id = "#{name.split(/\[/)[0]}_topic_types_auto_complete_extfield_#{extended_field.id}"
    id = "#{id}_multiple_#{@field_multiple_id}" if extended_field.multiple?
    spinner_id = "#{id}_spinner"
    html = text_field_with_auto_complete(
      name.split(/\[/)[0], '',
      { id: id, value: value, tabindex: '1', size: 50, name: name },
      {
        indicator: spinner_id,
        update: "#{id}_results",
        url: {
          controller: 'extended_fields',
          action: 'fetch_topics_from_topic_type',
          extended_field_id: extended_field.id,
          extended_field_for: name.split(/\[/)[0],
          multiple_id: (extended_field.multiple? ? @field_multiple_id : nil)
        }
      }
    )
    html += "<img src='#{image_path('indicator.gif')}' width='16' height='16' alt='#{t('extended_fields_helper.extended_field_topic_type_editor.getting_topics')}' id='#{spinner_id}' style='display:none;' />"

    # Add some images and text to indicate whether the value entered is valid or invalid
    checking_value = t('extended_fields_helper.extended_field_topic_type_editor.checking_value')
    valid_value = t('extended_fields_helper.extended_field_topic_type_editor.valid_value')
    invalid_value = t('extended_fields_helper.extended_field_topic_type_editor.invalid_value')
    html += <<-RUBY
      <span id='#{spinner_id}_checker' style='display:none;'>
        <img src='#{image_path('indicator.gif')}' width='16' height='16' alt='#{checking_value}' /> #{checking_value}...
      </span>
      <span id='#{id}_valid' style='display:none;'>
        <img src='/images/tick14x14.gif' width='14' height='14' alt='#{valid_value}' /> #{valid_value}
      </span>
      <span id='#{id}_invalid' style='display:none;'>
        <img src='/images/cross.png' width='16' height='16' alt='#{invalid_value}' /> #{invalid_value}
      </span>
    RUBY

    html
  end

  def extended_field_year_editor(name, value, tag_options, extended_field)
    html = text_field_tag(name + '[value]', (value['value'] if value), tag_options)
    if extended_field.circa?
      html += hidden_field_tag(name + '[circa]', '0')
      html += (check_box_tag(name + '[circa]', '1', (value && value['circa'].to_s == '1')) + 'Circa?')
    end
    html
  end

  # Generates label XHTML
  def extended_field_label(extended_field, required = false)
    options = required ? { class: 'required' } : {}
    required_icon = required ? ' <em>*</em>' : ''

    label_tag(id_for_extended_field(extended_field), display_label_for(extended_field) + required_icon, options)
  end

  def extended_field_example(extended_field)
    h(extended_field.example)
  end

  def additional_extended_field_control(extended_field, n)
    id = id_for_extended_field(extended_field) + '_additional'
    text = t(
      'extended_fields_helper.additional_extended_field_control.add_another',
      field_name: display_label_for(extended_field).singularize.downcase
    )
    url = {
      controller: 'extended_fields',
      action: 'add_field_to_multiples',
      extended_field_id: extended_field.id,
      n: n, item_key: @item_type_for_params
    }
    link_to(text, url, { id: id, remote: true })
  end

  def qualified_name_for_field(extended_field)
    extended_field.label.downcase.gsub(/\s/, '_')
  end

  # Get the existing value for a single extended field
  # Requires:
  # * extended_field: An instance of ExtendedField
  # * array: extended content pairs (i.e. ['field_name', 'value']) from the model
  def field_value_from_hash(extended_field, array)
    array.select { |k, v| k == qualified_name_for_field(extended_field) }.last.last
  rescue
    ''
  end

  # Get the existing values for a multiple value capable extended field.
  # Requires:
  # Same as above, plus:
  # * position_in_set: A number offset of the value want. The collection starts with key 1, not 0 as in a traditional associative
  #   array.
  def field_value_from_multiples_hash(extended_field, hash, position_in_set, level = 1)
    field_values = hash[qualified_name_for_field(extended_field) + '_multiple']
    field_values = field_values[position_in_set.to_s][qualified_name_for_field(extended_field)] || ''

    if field_values.is_a?(Hash) && extended_field.ftype != 'year'
      field_values.reject { |k, v| k == 'xml_element_name' }.sort.collect { |v| v.last } || []
    else
      field_values
    end
  rescue
    ''
  end

  # Get the keys of existing values for a 'multiple' extended field.
  # Requires:
  # * extended_field: An instance of ExtendedField
  # * hash: xml_attributes from the model.
  def existing_multiples_in(extended_field, hash)
    multiples = hash[qualified_name_for_field(extended_field) + '_multiple']
    # We need to to .last.last because what we get initially is like [['field_name', ['value', 'value,..]]] and we need to unnest
    # without flatten the values into the same dimension of the array as the field name.
    multiples.blank? ? nil : multiples.keys
  end

  # Get a list of choices for display
  def extended_field_choices_unordered_list
    if top_level = Choice.find_top_level
      content_tag(
        'ul',
        top_level.inject('') do |memo, choice|
          memo + list_item_for_choice(choice)
        end
      )
    else
      ''
    end
  end

  def list_item_for_choice(choice, options = {}, url_hash = {})
    options = {
      include_children: true,
      current: false,
    }.merge(options)

    url_hash = {
      urlified_name: params[:urlified_name] || @site_basket.urlified_name,
      controller_name_for_zoom_class: params[:controller_name_for_zoom_class] || 'topics',
    }.merge(url_hash)

    if params[:privacy_type].blank?
      method = 'basket_all_of_category_url'
    else
      method = 'basket_all_private_of_category_url'
      url_hash[:privacy_type] = params[:privacy_type]
    end

    base = content_tag(
      'li', link_to(
              choice.label, send(method, url_hash.merge(limit_to_choice: choice)),
              { title: choice.value }
      ),
      { class: (options[:current] ? 'current' : '') }
    )

    children = ''
    if options[:include_children]
      children = choice.children.inject('') { |memo, child| list_item_for_choice(child) }
    end

    children.blank? ? base : base + content_tag('ul', children.to_s)
  end

  private

  def base_name_for_extended_field(extended_field)
    "#{@item_type_for_params}[extended_content_values][#{qualified_name_for_field(extended_field)}]"
  end

  def name_for_extended_field(extended_field)
    base = base_name_for_extended_field(extended_field)
    extended_field.multiple? ? "#{base}[#{@field_multiple_id}]" : base
  end

  def id_for_extended_field(extended_field)
    create_safe_extended_field_string(name_for_extended_field(extended_field))
  end

  def create_safe_extended_field_string(string)
    string.delete(']').tr('[', '_')
  end
end
