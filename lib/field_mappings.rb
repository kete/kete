# frozen_string_literal: true

module FieldMappings
  unless included_modules.include? FieldMappings

    def self.included(klass)
      # RABID: it seems this module can only be included in 2 classes
      case klass.name
      when 'ContentTypeToFieldMapping'
        klass.send :belongs_to, :content_type
        klass.send :acts_as_list, scope: :content_type_id
      when 'TopicTypeToFieldMapping'
        klass.send :belongs_to, :topic_type
        klass.send :acts_as_list, scope: :topic_type_id
      else
        raise "ERROR: FieldMappings lib was included into an unsupported model class
        (expected: ContentTypeToFieldMapping or TopicTypeToFieldMapping, got: #{klass.name})."
      end

      klass.send :belongs_to, :extended_field
      klass.send :belongs_to, :form_field, class_name: 'ExtendedField', foreign_key: 'extended_field_id'
      klass.send :belongs_to, :required_form_field, class_name: 'ExtendedField', foreign_key: 'extended_field_id'

      klass.extend(ClassMethods)
    end

    module ClassMethods
      def add_as_to(is_required, type, field)
        with_scope(create: { required: is_required }) { type.concat field }
      end
    end

    # RABID:
    # Old Kete used a plugin called 'Piggy Back' which adjusted ActiveRecord
    # finder methods to load extra data. It used it to automatically load the
    # following attributes:
    #
    #   * ExtendedField#label
    #   * ExtendedField#xml_element_name
    #   * ExtendedField#xsi_type
    #   * ExtendedField#multiple
    #   * ExtendedField#description
    #   * ExtendedField#user_choice_addition
    #   * ExtendedField#ftype
    #
    # as attributes of whatever model this module is included into e.g.
    # ExtendedField#label would be available as #label in this class.
    #
    # See http://37signals.com/rails/wiki/PiggyBackQuery.html for the
    # basics of how PiggyBack worked and the vendor/plugins/piggy_back
    # directory in the old Kete code for the gory details.
    #
    # We just do the simpler (probably slower) thing until we are sure it is
    # a performance problem.

    def extended_field_label;                extended_field.label; end

    def extended_field_xml_element_name;     extended_field.xml_element_name; end

    def extended_field_xsi_type;             extended_field.xsi_type; end

    def extended_field_multiple;             extended_field.multiple; end

    def extended_field_description;          extended_field.description; end

    def extended_field_user_choice_addition; extended_field.user_choice_addition; end

    def extended_field_ftype;                extended_field.ftype; end

    def used_by_items?
      # Check whether we are dealing with a topic type mapping
      # or a content type mapping and get items accordingly
      @all_versions ||=
        if is_a?(TopicTypeToFieldMapping)
          Topic::Version.all(conditions: { topic_type_id: topic_type.full_set.collect { |tt| tt.id } })
        else
          if content_type.class_name == 'User'
            User.all
          else
            content_type.class_name.constantize::Version.all
          end
                               end

      ef_label = Regexp.escape(extended_field_label.downcase.tr(' ', '_'))
      element_label = extended_field_multiple ? "#{ef_label}_multiple" : ef_label
      @all_versions.any? do |version|
        version.extended_content =~ /<#{element_label}/ &&
          version.extended_content !~ /<#{element_label}[^>]*\/>/ &&
          version.extended_content !~ /<#{element_label}[^>]*>(<[0-9]+><#{ef_label}[^>]*><\/#{ef_label}><\/[0-9]+>)*<\/#{element_label}>/
      end
    end

    private

    def validate
      if is_a?(ContentTypeToFieldMapping) && private_only? && content_type.class_name == 'User'
        errors.add_to_base('Users cannot have private only mappings.')
      elsif required? && private_only?
        errors.add_to_base('Mapping cannot be required and private only.')
        false
      else
        true
      end
    end

  end
end
