module ExtendedFieldsHelper
  
  # Receives one of Topic#topic_type.topic_type_to_field_mapping (TopicTypeToFieldMapping)
  def extended_field_control(mapping)
    extended_field = mapping.extended_field
    
    # Construct the basic control
    base = extended_field_label(extended_field, required) + extended_field_editor(extended_field)
    
    # Generate and Id for the field (important for multiples
    generate_id_for_extended_field(extended_field)
    
    # Also display a control to add further field instances if necessary
    extended_field.multiple? ? base + additional_extended_field_control(extended_field) : base
  end
  
  def extended_field_label(extended_field, required = false)
    options = required ? { :class => "required" } : Hash.new
    
    label_tag(id_for_extended_field(extended_field), extended_field.label, options)
  end
  
  
  # Override for ActiveScaffold extended field controller edit view
  # Refer to http://activescaffold.com/docs/form-overrides for details
  def pseudo_choices_form_column(record, input_name)
    select :record, :pseudo_choices, 
      Choice.find(:all).collect { |c| [c.label, c.id] }, 
      { :selected => record.choices.collect { |c| c.id } }, 
      { :multiple => true, :name => input_name + "[]" }
  end
  
  private
  
    def id_for_extended_field(extended_field)
      base = "topic_extended_content[#{xhtml_name_for_extended_field}]"
      extended_field.multiple? ? "#{base}[#{@field_multiple_id}]" : base
    end
  
    def generate_id_for_extended_field(extended_field)
      @field_multiple_id = index_of_multiple_field(extended_field) if extended_field.multiple?
    end
  
    def xhtml_name_for_field(extended_field)
      extended_field.label.gsub(/\s+/, "_")
    end
  
    # We need to be careful when handling extended fields that can have multiples.
    # So, keep track of IDs for fields as offering them
    def index_of_multiple_field(extended_field)
    
      # Initialize the storage of existing indexes
      @multiple_field_indexes ||= HashWithIndifferentAccess.new
      @multiple_field_indexes[xhtml_name_for_field(extended_field)] ||= 0 # We start at 1 (see below)
    
      # Increment and kick off the new ID
      @multiple_field_indexes[xhtml_name_for_field(extended_field)] = \
        @multiple_field_indexes[xhtml_name_for_field(extended_field)] + 1
    end
  
end