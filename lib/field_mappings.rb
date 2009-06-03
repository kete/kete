module FieldMappings
  unless included_modules.include? FieldMappings

    def self.included(klass)
      case klass.name
      when 'ContentTypeToFieldMapping'
        klass.send :belongs_to, :content_type
        klass.send :acts_as_list, :scope => :content_type_id
      when 'TopicTypeToFieldMapping'
        klass.send :belongs_to, :topic_type
        klass.send :acts_as_list, :scope => :topic_type_id
      else
        raise "ERROR: FieldMappings lib was included into an unsupported model class
        (expected: ContentTypeToFieldMapping or TopicTypeToFieldMapping, got: #{klass.name})."
      end

      klass.send :belongs_to, :extended_field
      klass.send :belongs_to, :form_field, :class_name => "ExtendedField", :foreign_key => "extended_field_id"
      klass.send :belongs_to, :required_form_field, :class_name => "ExtendedField", :foreign_key => "extended_field_id"

      klass.send :piggy_back, :extended_field_label_xml_element_name_xsi_type_multiple_description_user_choice_addition_and_ftype,
          :from => :extended_field, :attributes => [:label, :xml_element_name, :xsi_type, :multiple, :description, :user_choice_addition, :ftype]

      klass.extend(ClassMethods)
    end

    module ClassMethods
      def add_as_to(is_required, type, field)
        with_scope(:create => { :required => is_required }) { type.concat field }
      end
    end

    def used_by_items?
      ef_label = Regexp.escape(extended_field.label_for_params)
      element_label = extended_field.multiple? ? "#{ef_label}_multiple" : ef_label

      like, not_like = case ActiveRecord::Base.connection.adapter_name.downcase
        when /postgres/ then ["~*", "!~*"]
        else                 ["REGEXP", "NOT REGEXP"]
      end

      conditions = ["extended_content #{like} ? AND extended_content #{not_like} ? AND extended_content #{not_like} ?",
                    "<#{element_label}", "<#{element_label}[^>]*\/>", "<#{element_label}[^>]*>(<[0-9]+><#{ef_label}[^>]*><\/#{ef_label}><\/[0-9]+>)*<\/#{element_label}>"]

      # Check whether we are dealing with a topic type mapping
      # or a content type mapping and get items accordingly
      items_count = if self.is_a?(TopicTypeToFieldMapping)
        conditions[0] += " AND topic_type_id IN (?)"
        conditions << topic_type.full_set.collect { |tt| tt.id }
        Topic::Version.count(:conditions => conditions)
      else
        content_type.class_name.constantize::Version.count(:conditions => conditions)
      end

      items_count > 0
    end

  end
end