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

      # RABID: piggy_back is a way of avoiding doing multiple queries to get attributes from associated models
      # * see http://37signals.com/rails/wiki/PiggyBackQuery.html for the basics
      # * This reads as:
      # * the horrible long attribute is just a unique name for the piggy back

      # * it reads as "When you search for klass in the database, manipulate
      # * the SQL so that it also selects the attributes named below from the
      # * 'extended_fields' table."
      # e.g. a find query that results in
      #   SELECT id,name FROM users;
      # would become something like
      #   SELECT users.id, users.name, extended_fields,label, extended_fields.xml_element_name ... FROM users, extended_fields; 
      klass.send :piggy_back, 
                 :extended_field_label_xml_element_name_xsi_type_multiple_description_user_choice_addition_and_ftype,
                 :from => :extended_field, 
                 :attributes => [:label, :xml_element_name, :xsi_type, :multiple, :description, :user_choice_addition, :ftype]

      klass.extend(ClassMethods)
    end

    module ClassMethods
      def add_as_to(is_required, type, field)
        with_scope(:create => { :required => is_required }) { type.concat field }
      end
    end

    def used_by_items?
      # Check whether we are dealing with a topic type mapping
      # or a content type mapping and get items accordingly
      @all_versions ||= if self.is_a?(TopicTypeToFieldMapping)
        Topic::Version.all(:conditions => { :topic_type_id => topic_type.full_set.collect { |tt| tt.id } })
      else
        if content_type.class_name == 'User'
          User.all
        else
          content_type.class_name.constantize::Version.all
        end
      end

      ef_label = Regexp.escape(extended_field_label.downcase.gsub(/ /, '_'))
      element_label = extended_field_multiple ? "#{ef_label}_multiple" : ef_label
      @all_versions.any? do |version|
        version.extended_content =~ /<#{element_label}/ &&
        version.extended_content !~ /<#{element_label}[^>]*\/>/ &&
        version.extended_content !~ /<#{element_label}[^>]*>(<[0-9]+><#{ef_label}[^>]*><\/#{ef_label}><\/[0-9]+>)*<\/#{element_label}>/
      end
    end

    private

    def validate
      if self.is_a?(ContentTypeToFieldMapping) && private_only? && self.content_type.class_name == 'User'
        errors.add_to_base("Users cannot have private only mappings.")
      elsif required? && private_only?
        errors.add_to_base("Mapping cannot be required and private only.")
        false
      else
        true
      end
    end

  end
end