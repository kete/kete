module ExtendedFieldsHelper
  
  # Override for ActiveScaffold extended field controller edit view
  # Refer to http://activescaffold.com/docs/form-overrides for details
  def pseudo_choices_form_column(record, input_name)
    parent_choices = Choice.find(:all, :conditions => 'parent_id IS NULL', :order => 'label ASC')
    
    all_choices = parent_choices.collect do |parent|
      [[parent.label, parent.id]] + parent.children.find(:all, :order => 'label ASC').collect { |c| ["- #{c.label}", c.id] }
    end
    
    choices_for_select = all_choices.inject([]) { |result, c| result.concat(c) }
    
    select :record, :pseudo_choices, 
      choices_for_select, 
      { :selected => record.choices.collect { |c| c.id } }, 
      { :multiple => true, :name => input_name + "[]" }
  end
  
  # Same as above, but for ftype.
  # We are not being strict about which ftypes are allowed and which are not.
  def ftype_form_column(record, input_name)

    options_for_select = [
      ['Check box', 'checkbox'],
      ['Radio button', 'radio'],
      ['Date', 'date'],
      ['Text', 'text'],
      ['Text box', 'textarea'],
      ['Choices (drop-down)', 'choice']
    ]
    
    select(:record, :ftype, options_for_select, { :select => record.ftype }, :name => input_name)
  end
  
  # Same as above, but for choice hierarchy
  def parent_form_column(record, input_name)
    select(:record, :parent_id, 
      [['', nil]] + Choice.find(:all).reject { |c| c.id == record.id }.map { |c| [c.label, c.id] },
      { :select => record.parent_id }, :name => input_name)
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
      :id => id_for_extended_field(extended_field),
      :tabindex => 1
    }
    
    # Compile tag XHTML name
    name = name_for_extended_field(extended_field)
    
    builder = "extended_field_#{extended_field.ftype}_editor".to_sym
    if extended_field.ftype == "choice"
      send(:extended_field_choice_editor, name, value, tag_options, extended_field)
    elsif respond_to?(builder)
      send(builder, name, value, tag_options)
    else
      send(:extended_field_text_editor, name, value, tag_options)
    end
  end
  
  def extended_field_checkbox_editor(name, value, options)
    content_tag("div", check_box_tag(name, "Yes", (value.to_s == "Yes"), options), "style" => "margin: 4px")
  end
  
  # def extended_field_radio_editor(name, value, options)
  #   # Not implemented. How would this be used?
  # end
  
  def extended_field_date_editor(name, value, options)
    extended_field_text_editor(name, value, options)
  end
  
  def extended_field_text_editor(name, value, options)
    text_field_tag(name, value, options)
  end
  
  def extended_field_textarea_editor(name, value, options)
    text_area_tag(name, value, options.merge(:rows => 5))
  end
  
  def extended_field_choice_editor(name, value, options, extended_field)
    
    # Provide an appropriate selection interface..
    if extended_field.choices.size < 15
      extended_field_choice_dropdown_editor(name, value, options, extended_field)
    else
      extended_field_choice_autocomplete_editor(name, value, options, extended_field)
    end
  end
  
  def extended_field_choice_dropdown_editor(name, value, options, extended_field)
    option_tags = options_for_select(extended_field.choices.map { |c| [c.label, c.value] }, value)
    select_tag(name, option_tags, options)
  end
  
  def extended_field_choice_autocomplete_editor(name, value, options, extended_field)
    
    # Build a list of available choices
    choices = extended_field.choices.map { |c| c.label }
    
    # Because we store the choice's value, not label, we need to find the label to be shown in the text field.
    # We also handle validation failures here by displaying the submitted value.
    value = Choice.find_by_value(value).label rescue value
    
    text_field_tag(name, value, options.merge(:autocomplete => "off")) + tag("br") +
    content_tag("div", nil, :class => "extended_field_autocomplete", :id => options[:id] + "_autocomplete", :style => "display: none") +
    
    # Javascript code to initialize the autocompleter
    javascript_tag("new Autocompleter.Local('#{options[:id]}', '#{options[:id] + "_autocomplete"}', #{array_or_string_for_javascript(choices)}, { })") + 
    
    # We need to let our controller know that we're using autocomplete for this field.
    hidden_field_tag(name.first(name.length - 1) + "_from_autocomplete]", "true", :id => options[:id] + "_from_autocomplete")
  end
  
  # Generates label XHTML
  def extended_field_label(extended_field, required = false)
    options = required ? { :class => "required" } : Hash.new
    
    label_tag(id_for_extended_field(extended_field), extended_field.label, options)
  end
  
  def additional_extended_field_control(extended_field, n)
    id = id_for_extended_field(extended_field) + "_additional"
    
    link_to_remote("Add another field", :url => { :controller => 'extended_fields', :action => 'add_field_to_multiples', :extended_field_id => extended_field.id, :n => n, :item_key => @item_type_for_params }, :id => id)
  end
  
  def qualified_name_for_field(extended_field)
    extended_field.label.downcase.gsub(/\s/, "_")
  end
  
  # Get the existing value for a single extended field
  # Requires:
  # * extended_field: An instance of ExtendedField
  # * array: extended content pairs (i.e. ['field_name', 'value']) from the model
  def field_value_from_hash(extended_field, array)
    array.select { |k, v| k == qualified_name_for_field(extended_field) }.flatten.last || ""
  rescue
    ""
  end
  
  # Get the existing values for a multiple value capable extended field.
  # Requires:
  # Same as above, plus:
  # * position_in_set: A number offset of the value want. The collection starts with key 1, not 0 as in a traditional associative 
  #   array.
  def field_value_from_multiples_hash(extended_field, hash, position_in_set)
    field_values = hash[qualified_name_for_field(extended_field) + "_multiple"]
    field_values = field_values[position_in_set.to_s][qualified_name_for_field(extended_field)] || ""
    
    if field_values.is_a?(Hash)
      field_values["value"] || ""
    else
      field_values
    end
    
  rescue
    ""
  end
  
  # Get the keys of existing values for a 'multiple' extended field.
  # Requires:
  # * extended_field: An instance of ExtendedField
  # * hash: xml_attributes from the model.
  def existing_multiples_in(extended_field, hash)
    multiples = hash[qualified_name_for_field(extended_field) + "_multiple"]
    # We need to to .last.last because what we get initially is like [['field_name', ['value', 'value,..]]] and we need to unnest
    # without flatten the values into the same dimension of the array as the field name.
    multiples.blank? ? nil : multiples.keys
  end
  
  private
  
    def base_name_for_extended_field(extended_field)
      "#{@item_type_for_params}[extended_content][#{qualified_name_for_field(extended_field)}]"
    end
    
    def name_for_extended_field(extended_field)
      base = base_name_for_extended_field(extended_field)
      extended_field.multiple? ? "#{base}[#{@field_multiple_id}]" : base
    end
    
    def id_for_extended_field(extended_field)
      name_for_extended_field(extended_field).gsub(/\]/, "").gsub(/\[/, '_')
    end
  
end