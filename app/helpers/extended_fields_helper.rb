module ExtendedFieldsHelper
  
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
  
  def extended_field_editor(extended_field, value = nil)
    options = {
      :id => id_for_extended_field(extended_field),
      :tabindex => 1
    }
    text_field_tag(name_for_extended_field(extended_field), value, options)
  end
  
  # Generates label XHTML
  def extended_field_label(extended_field, required = false)
    options = required ? { :class => "required" } : Hash.new
    
    label_tag(id_for_extended_field(extended_field), extended_field.label, options)
  end
  
  def additional_extended_field_control(extended_field)
    id = base_name_for_extended_field(extended_field).gsub(/[\[\]]/, '_') + "additional"
    
    link_to_function("Add another field", nil, :id => id) do |page|
      page.call "alert(\"Not implemented.\")"
    end
  end
  
  
  # Override for ActiveScaffold extended field controller edit view
  # Refer to http://activescaffold.com/docs/form-overrides for details
  def pseudo_choices_form_column(record, input_name)
    select :record, :pseudo_choices, 
      Choice.find(:all).collect { |c| [c.label, c.id] }, 
      { :selected => record.choices.collect { |c| c.id } }, 
      { :multiple => true, :name => input_name + "[]" }
  end
  
  def qualified_name_for_field(extended_field)
    extended_field.label.downcase.gsub(/\s/, "_")
  end
  
  def field_value_from_hash(extended_field, array)
    array.select { |k, v| k == qualified_name_for_field(extended_field) }.flatten.last
  rescue
    ""
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
  
    def generate_id_for_extended_field(extended_field)
      @field_multiple_id = index_of_multiple_field(extended_field) if extended_field.multiple?
    end
  
    # We need to be careful when handling extended fields that can have multiples.
    # So, keep track of IDs for fields as offering them
    def index_of_multiple_field(extended_field)
    
      # Initialize the storage of existing indexes
      @multiple_field_indexes ||= HashWithIndifferentAccess.new
      @multiple_field_indexes[qualified_name_for_field(extended_field)] ||= 0 # We start at 1 (see below)
    
      # Increment and kick off the new ID
      @multiple_field_indexes[qualified_name_for_field(extended_field)] = \
        @multiple_field_indexes[qualified_name_for_field(extended_field)] + 1
    end
  
end