# frozen_string_literal: true

# useful methods for testing extended content related functionality
# assumes @new_model and @base_class vars, as in standard Kete item unit tests
module ExtendedContentHelpersForTestSetUp
  def create_and_map_extended_field_to_type(options = {})
    @should_create_extended_item = !options[:should_create_extended_item].nil? ? options.delete(:should_create_extended_item) : true

    # add a extended field to the base class or topic type in the case of topics
    create_extended_field(options)

    if @should_create_extended_item
      @extended_item = Module.class_eval(@base_class).create! @new_model
    end

    unless @base_class == 'Topic'
      @mapped_to_type_instance = ContentType.find_by_class_name(@base_class)
    else
      @mapped_to_type_instance = @extended_item.topic_type
    end

    @mapped_to_type_instance.form_fields << @extended_field

    unless @base_class == 'Topic'
      @mapping = @extended_field.content_type_to_field_mappings.last
    else
      @mapping = @extended_field.topic_type_to_field_mappings.last
    end
  end
end
