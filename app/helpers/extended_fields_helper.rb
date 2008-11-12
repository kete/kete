module ExtendedFieldsHelper
  
  # Override for ActiveScaffold extended field controller edit view
  # Refer to http://activescaffold.com/docs/form-overrides for details
  
  # Using YUI TreeView
  def pseudo_choices_form_column(record, input_name)
    top_level = Choice.find_top_level
    id = "tree_" + record.id.to_s
    
    # Containing DIV for theme
    '<div class="yui-skin-sam" style="float: left" id="hidden_choices_select_' + record.id.to_s + '">' +
    
    # Expand all and collapse all links
    content_tag("p", link_to_function("Expand all", "", :id => "#{id}_expand") + " | " + link_to_function("Collapse all", "", :id => "#{id}_collapse")) +
    
    # Actual XHTML list that is shown in the case JS fails or is not supported
    '<div id="choice_selection_' + record.id.to_s + '"><ul>' +
    top_level.inject("") do |m, choice|
      m = m + build_ul_for_choice(choice, record)
    end +
    '</ul></div></div>' +
    
    # Javascript call to initialise YUI TreeView, and listens for expand/collapse links
    '<script type="text/javascript>var ' + id + ' = new YAHOO.widget.TreeView(document.getElementById("choice_selection_' + record.id.to_s + '"), [' + top_level.map { |t| build_node_array_for(t, record) }.join(", ") + ']); ' + id + '.render(); ' + id + '.subscribe("clickEvent", function(ev, node) { return false; }); YAHOO.util.Event.addListener("' + id + '_expand", "click", function(tree) { ' + id + '.expandAll(); }, ' + id + '); YAHOO.util.Event.addListener("' + id + '_collapse", "click", function(tree) {  ' + id + '.collapseAll(); }, ' + id + ');</script>' +
    
    (%w(choice autocomplete).member?(record.ftype) ? "" : javascript_tag("$('hidden_choices_select_#{record.id.to_s}').hide();"))
  end
  
  # Build hierarchical UL, LI structure for a choice and recurse through children elements
  def build_ul_for_choice(choice, record)
    content_tag("li", check_box_tag("record[pseudo_choices][]", choice.id.to_s, record.choices.member?(choice)) + " " + choice.label + build_ul_for_children_of(choice, record))
  end
  
  # Build hierarchicial UL, LI for children elements of a choice
  def build_ul_for_children_of(choice, record)
    if choice.children.empty?
      ""
    else
      "<ul>" + 
      choice.children.inject("") do |m, child|
        m = m + build_ul_for_choice(child, record)
      end + 
      "</ul>"
    end
  end
  
  # Create a Javascript array of hashes containing attributes for the construction of the TreeView.
  # This is necessary because YUI's TreeView doesn't probably interpret checkboxes in XHTML when
  # constructing a TreeView from existing content (ala progressive enhancement).
  def build_node_array_for(choice, record)
    string_from_children = choice.children.map { |child| build_node_array_for(child, record) }.join(", ")
    
    output = ["{type:'html', html:'#{check_box_tag("record[pseudo_choices][]", choice.id.to_s, record.choices.member?(choice))} #{choice.label}', expanded:#{(record.choices.member?(choice) || choice.all_children.any? { |c| record.choices.member?(c) }).to_s}"]
    output << ", children: [#{string_from_children}]" unless string_from_children.blank?
    output << "}"
    
    output.join
  end
  
  # More ActiveScaffold overloading..
  
  # Same as above, but for ftype.
  # We are not being strict about which ftypes are allowed and which are not.
  def ftype_form_column(record, input_name)

    options_for_select = [
      ['Check box', 'checkbox'],
      ['Radio buttons', 'radio'],
      ['Date', 'date'],
      ['Text', 'text'],
      ['Text box', 'textarea'],
      ['Choices (auto-completion)', 'autocomplete'],
      ['Choices (drop-down)', 'choice']
    ]
    
    select(:record, :ftype, options_for_select, { :select => record.ftype }, :name => input_name, :onchange => "if ( Form.Element.getValue(this) == 'autocomplete' || Form.Element.getValue(this) == 'choice' ) { $('hidden_choices_select_#{record.id.to_s}').show(); } else { $('hidden_choices_select_#{record.id.to_s}').hide(); }" )
  end
  
  # Same as above, but for choice hierarchy
  def parent_form_column(record, input_name)
    if record.new_record?
      
      # Due to a limitation on better-nested-set, you cannot move_to any node unless the node you're
      # moving has already been saved. The intention here is that hierarchical manipulation of choices 
      # will be done from the parent side.
      "You cannot select a parent choice until the choice has been created."
    else
      
      select(:record, :parent_id, 
        Choice.find(:all).reject { |c| c.id == record.id }.map { |c| [c.label, c.id] },
        { :select => record.parent_id }, :name => input_name)
    end
  end
  
  # Same as above, but for choice children selection
  def children_form_column(record, input_name)
    if record.new_record?
      
      # Due to a limitation on better-nested-set, you cannot move_to any node unless the node you're
      # moving has already been saved. The intention here is that hierarchical manipulation of choices 
      # will be done from the parent side.
      "You cannot select child choices until the choice has been created."
    else
      
      currently_selected = record.children.map do |choice|
        check_box_tag("record[children][]", choice.id, true) + " " + choice.label
      end
      
      candidates = Choice.root.children.reject { |c| record.parent == c || record == c }.map do |choice|
        check_box_tag("record[children][]", choice.id, false) + " " + choice.label
      end
      
      output = content_tag("h6", "Existing sub-choices")
      output << "<ul>" + currently_selected.inject("") do |memo, choice|
        memo = memo + content_tag("li", choice)
      end + "</ul>"
      
      output << content_tag("h6", "Add more sub-choices")
      output << "<ul>" + candidates.inject("") do |memo, choice|
        memo = memo + content_tag("li", choice)
      end + "</ul>"
      
      content_tag("div", output, :style => "float: left")
    end
  end
  
  # Ensure children of a choice are displayed in a reasonable manner
  def children_column(record)
    record.children.map { |c| c.label }.join(", ")
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
    if %w(choice autocomplete).member?(extended_field.ftype)
      send(:extended_field_choice_editor, name, value, tag_options, extended_field)
    elsif respond_to?(builder)
      send(builder, name, value, tag_options)
    else
      send(:extended_field_text_editor, name, value, tag_options)
    end
  end
  
  def extended_field_checkbox_editor(name, value, options)
    check_box_tag(name, "Yes", (value.to_s == "Yes"), options)
  end
  
  def extended_field_radio_editor(name, existing_value, options)
    default_choices = [["Yes", "Yes"], ["No", "No"], ["No value", ""]]
    
    # In the future we might allow radio buttons to be used for selecting choices
    # choices = extended_field.choices.empty? ? default_choices : extended_field.choices.find_top_level.map { |c| [c.label, c.value] }
      
    html = default_choices.map do |label, value|
      radio_button_tag(name, value, existing_value.to_s == value) + " " + label
    end.join("<br />\n")
    
    content_tag("div", html, "class" => "extended_field_radio_button_collection")
  end
  
  def extended_field_date_editor(name, value, options)
    extended_field_text_editor(name, value, options)
  end
  
  def extended_field_text_editor(name, value, options)
    text_field_tag(name, value, options)
  end
  
  def extended_field_textarea_editor(name, value, options)
    text_area_tag(name, value, options.merge(:rows => 5, :class => "extended_field_textarea"))
  end
  
  def extended_field_choice_editor(name, value, options, extended_field)
    
    # Provide an appropriate selection interface..
    partial = extended_field.ftype == "choice" ? 'choice_select_editor' : 'choice_autocomplete_editor'
    
    # Generate the choices we need to populate the SELECT or autocomplete.
    choices = extended_field.choices.find_top_level
    
    # If the top level is empty, find lower level tags to display
    choices = choices.blank? ? extended_field.choices.reject { |c| extended_field.choices.member?(c.parent) } : choices
    
    render :partial => 'extended_fields/' + partial, :locals => { 
      :name => name, 
      :value => value, 
      :options => options, 
      :extended_field => extended_field,
      :choices => choices,
      
      # The default level is 1.. is this increased by subsequent renderings in ExtendedFieldsController.
      :level => 1
    }
  end
  
  def extended_field_choice_select_editor(name, value, options, extended_field, choices, level = 1)
    
    # Build OPTION tags
    option_tags = options_for_select([['', '']] + choices.map { |c| [c.label, c.value] }, value)
    
    default_options = {
      :onchange => remote_function(:url => {
        :controller => 'extended_fields', :action => 'fetch_subchoices', :for_level => level
      }, :with => "'value='+Form.Element.getValue(this)+'&options[name]=#{name}&options[value]=#{value}&options[extended_field_id]=#{extended_field.id}&item_type_for_params=#{@item_type_for_params}&field_multiple_id=#{@field_multiple_id}&editor=select'")
    }
    
    select_tag("#{name}[#{level}]", option_tags, default_options.merge(options))
  end
  
  def extended_field_choice_autocomplete_editor(name, value, options, extended_field, choices, level = 1)
    
    # Build a list of available choices
    choices = choices.map { |c| c.label }
    
    # Because we store the choice's value, not label, we need to find the label to be shown in the text field.
    # We also handle validation failures here by displaying the submitted value.
    selected_choice = Choice.find_by_value(value) || Choice.find_by_label(value)
    value = selected_choice && !value.blank? ? selected_choice.label : nil
    
    remote_call = remote_function(:url => {
        :controller => 'extended_fields', :action => 'fetch_subchoices', :for_level => level
      }, :with => "'label='+Form.Element.getValue(el)+'&options[name]=#{name}&options[value]=#{value}&options[extended_field_id]=#{extended_field.id}&item_type_for_params=#{@item_type_for_params}&field_multiple_id=#{@field_multiple_id}&editor=autocomplete'")
    
    text_field_tag("#{name}[#{level}]", value, options.merge(:id => "#{id_for_extended_field(extended_field)}_#{level}", :autocomplete => "off")) + tag("br") +
    content_tag("div", nil, 
      :class => "extended_field_autocomplete", 
      :id => id_for_extended_field(extended_field) + "_autocomplete_#{level}", 
      :style => "display: none"
    ) +
    
    # Javascript code to initialize the autocompleter
    javascript_tag("new Autocompleter.Local('#{id_for_extended_field(extended_field)}_#{level}', '#{id_for_extended_field(extended_field)}_autocomplete_#{level}', #{array_or_string_for_javascript(choices)}, { afterUpdateElement:function(el, sel) { #{remote_call} } });") +
    
    # We need to let our controller know that we're using autocomplete for this field.
    # We know the field we expect should be something like topic[extended_content][someonething]..
    
    hidden_field_tag("#{name.split(/\[/).first}[extended_content][#{name.scan(/\[([a-z_]*)\]/).flatten.at(1)}_from_autocomplete]", "true", :id => id_for_extended_field(extended_field) + "_from_autocomplete")
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
    array.select { |k, v| k == qualified_name_for_field(extended_field) }.last.last
  rescue
    ""
  end
  
  # Get the existing values for a multiple value capable extended field.
  # Requires:
  # Same as above, plus:
  # * position_in_set: A number offset of the value want. The collection starts with key 1, not 0 as in a traditional associative 
  #   array.
  def field_value_from_multiples_hash(extended_field, hash, position_in_set, level = 1)
    field_values = hash[qualified_name_for_field(extended_field) + "_multiple"]
    field_values = field_values[position_in_set.to_s][qualified_name_for_field(extended_field)] || ""
    
    if field_values.is_a?(Hash)
      field_values.reject { |k, v| k == "xml_element_name" }.values || []
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
  
  # Get a list of choices for display
  def extended_field_choices_unordered_list
    if top_level = Choice.find_top_level
      content_tag("ul",
      
        top_level.inject("") { |memo, choice|
          memo + list_item_for_choice(choice)
        }
      
      )
    else
      ""
    end
  end
  
  def list_item_for_choice(choice)
    url_hash = {
      :controller_name_for_zoom_class => params[:controller_name_for_zoom_class] || 'topics',
      :controller => 'search',
      :for => 'all'
    }

    if params[:privacy_type].blank?
      method = 'basket_all_of_category_url'
    else
      method = 'basket_all_private_of_category_url'
      url_hash.merge!(:privacy_type => params[:privacy_type])
    end
      
    base = content_tag("li", link_to(choice.label, send(method, url_hash.merge(:limit_to_choice => choice.value))))
    
    children = choice.children.inject("") { |memo, child| list_item_for_choice(child) }
    
    children.blank? ? base : base + content_tag("ul", children.to_s)
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