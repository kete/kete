# Requirements for XML conversion of extended fields
require "rexml/document"
require 'builder'

# ExtendedContent provides a way to access additional, extended content directly on a model. (ExtendedContent is included in all
# Kete content types.)
#
# Extended Content definitions are configured separately by users with ExtendedField records which are mapped to topic types or
# content types via the TopicTypeToFieldMapping and ContentTypeToFieldMapping relationship models. So, the relationships between
# item classes and extended fields is something like AudioRecording -> ContentTypeToFieldMapping(s) -> ExtendedField. In the case
# of Topics the relations are Topic -> TopicType -> TopicTypeToFieldMapping(s) -> ExtendedField. Refer to the individual classes
# for more information.
#
# On the model, extended content can be accessed by the #extended_content_values accessor methods, and in the future by individual
# accessor methods for each field. Behind the scenes the data received as a Hash instance of values (or single value in the case
# of accessor methods) is stored into a particular XML data structure in the #extended_content attribute, which is present as a
# column in the item class's table.

module ExtendedContent
  CLASSES_WITH_SUMMARIES = ['Topic', 'Document']

  unless included_modules.include? ExtendedContent

    include ExtendedContentHelpers

    include GoogleMap::ExtendedContent

    # Provide an instance of Builder::XmlMarkup for creating the XML representation stored in each item's extended content
    # attribute.
    def xml(force_new = false)
      if force_new
        @builder_xml = Builder::XmlMarkup.new
      else
        @builder_xml ||= Builder::XmlMarkup.new
      end
    end

    # Return key value pairs of extended field content stored in #extended_content.
    #
    # Example:
    # An item with extended fields mapped with 'Field one' with a single value ('value for field one') and 'Field two' with
    # multiple values ('first value for field two', 'second value for field two', would return the following:
    # [['field_one', 'value for field one'], ['field_two', ['first value for field two', 'second value for field two']]]
    alias_method :extended_content_pairs, :convert_xml_to_key_value_hash

    # Return a hash of values for extended field content
    #
    # Example:
    # If the following XML is in #extended_content: <some_tag xml_element_name="dc:something">something</some_tag>
    # <some_other_tag xml_element_name="dc:something_else">something_else</some_other_tag>, then the following would be
    # returned:
    # { "some_tag" => { "xml_element_name" => "dc:something", "value" => "something" }, "some_other_tag" => {
    # "xml_element_name" => "dc:something_else", "value" => "something_else" } }
    alias_method :extended_content_values, :convert_xml_to_extended_fields_hash

    # The setter used to save extended content into XML. This accepts an array directly from params (i.e.
    # params[:topic][:extended_content_values], etc). This allows you do to topic.update_attributes(:extended_content_values
    #  => '..'), for example. This is heavily used for creating and updating items with extended fields mapped by views and
    # controller methods.
    # The format received has several conventions.
    # For instance, for single values, the structure for the content as array hash would be { "field_name" => "value" }, but
    # for multiple values would be { "field_name" => { "1" => "value one", "2" => "value two" } }.
    def extended_content_values=(content_as_array)
      # Do the behind the scenes stuff..
      self.extended_content = convert_extended_content_to_xml(content_as_array)
    end

    # Pulls xml attributes in extended_content column out into a hash wrapped in a key that corresponds to the fields position
    # Example output:
    # => { "1" => { "first_names" => "Joe" }, "2" => { "last_name" => "Bloggs" }, "3" => { "place_of_birth" => { "xml_element_name" => "dc:subject" } } }
    def xml_attributes
      # TODO: replace rexml with nokogiri
      # we use rexml for better handling of the order of the hash
      extended_content = REXML::Document.new("<dummy_root>#{self.extended_content}</dummy_root>")

      temp_hash = Hash.new
      root = extended_content.root
      position = 1

      form_fields = all_field_mappings

      if form_fields.size > 0
        form_fields.each do |extended_field_mapping|
          f_id = extended_field_mapping.extended_field_label.downcase.gsub(/\s/, '_')
          f_multiple = "#{f_id}_multiple"
          field_xml = root.elements[f_multiple]
          # if we didn't match a multiple
          # then we are all clear to use the plain f_id
          if field_xml.blank?
            field_xml = root.elements[f_id]
          end
          if !field_xml.blank?
            temp_hash[position.to_s] = Hash.from_xml(field_xml.to_s)
            position += 1
          end
        end
      end

      return temp_hash
    end

    # Refer to #xml_attributes.
    alias :extended_content_ordered_hash :xml_attributes

    # Pulls a hash of values from XML without position references (i.e. contrary to #xml_attributes).
    # Example output:
    # =>
    # { "first_names"=> {
    #     "xml_element_name" => "dc:description", "value" => "Joe"
    #   },
    #   "address_multiple"=> {
    #     "1" => { "address" => { "xml_element_name" => "dc:description", "value" => "The Parade" } },
    #     "2" => { "address" => { "xml_element_name" => "dc:description", "value" => "Island Bay" } }
    #   }
    # }
    def xml_attributes_without_position
      # we use rexml for better handling of the order of the hash

      XmlSimple.xml_in("<dummy>#{extended_content}</dummy>", "contentkey" => "value", "forcearray" => false)

      # TODO: Clean this up

      # OLD METHOD
      # extended_content_hash = Hash.from_xml("<dummy_root>#{self.extended_content}</dummy_root>")
      # return extended_content_hash["dummy_root"]
    end

    # Checks whether the current class (Topic, AudioRecording, etc) can have a short summary
    # NOTE: Unsure how this relates to extended content
    def can_have_short_summary?
      CLASSES_WITH_SUMMARIES.include?(self.class.name)
    end

    # given a
    def reader_for(extended_field_element_name)
      extended_content_pairs[extended_field_element_name]
    end

    # this will take existing extend_content's xml
    # and replace the value for only the specified xml_element
    # which is extended_field.label_for_params
    def replace_value_for(extended_field_element_name, value, content_hash = nil)
      # get existing datastructure transformed to a hash
      content_hash = xml_attributes_without_position unless content_hash

      multiple_name = extended_field_element_name + '_multiple'

      # if the extended field hasn't already been added to the datastructure
      unless content_hash.keys.include?(extended_field_element_name) ||
          content_hash.keys.include?(multiple_name)
        raise "#{extended_field_element_name} must already be in extended_content xml datastructure for this method to work."
      end

      # replace value
      if content_hash.keys.include?(extended_field_element_name)
        content_hash[extended_field_element_name]['value'] = value
      else content_hash.keys.include?(multiple_name)
        # skipping multiples for now
        # content_hash[multiple_name] = value
      end

      # prepare the xml content to stuff back in
      # WARNING - xmlsimple may not like multiple hash keys that are only numbers and do the wrong thing
      # multiples are skipped for now
      xml_string = XmlSimple.xml_out(content_hash, "contentkey" => "value")

      # we pull of the opt opening and closing tags that xml simple adds
      xml_string.sub!(/^<opt>/, '').sub!(/<\/opt>$/, '')

      extended_content = xml_string
    end

    # same as replace_value_for
    # except it will create an element
    # if the extended_content's xml doesn't already have one
    def replace_value_or_create_element_for(extended_field_element_name, value)
      content_hash = xml_attributes_without_position

      multiple_name = extended_field_element_name + '_multiple'

      if content_hash.keys.include?(extended_field_element_name) ||
          content_hash.keys.include?(multiple_name)
        replace_value_for(extended_field_element_name, value, content_hash)
      else
        # add this field to the hash
        # content_hash =
      end
    end

    # grab existing value and add to it
    def append_value_for(extended_field_element_name, additional_value)
    end

    private
    # we want dynamic setters (= and +=) and getters for our extended fields
    # we dynamically extend the model with method definitions when a new field_mapping is added
    # triggered by the after_create and after_destroy methods in the join model

    # first up, define the three skeleton methods
    def self.define_methods_for(extended_field)
      base_method_name = extended_field.label_for_params

      define_method(base_method_name) do
        reader_for(base_method_name)
      end

      define_method(base_method_name + '=') do |value|
        replace_value_or_create_element_for(base_method_name, value)
      end

      define_method(base_method_name + '+=') do |value|
        append_value_for(base_method_name, additional_value)
      end
    end

    def self.undefine_methods_for(extended_field)
      base_method_name = extended_field.label_for_params

      ['', '=', '+='].each do |method_operator|
        remove_method(base_method_name + method_operator)
      end
    end

    # usually when a new extended field is mapped to a content type or a topic type
    # corresponding methods are defined
    # however these dynamic methods definitions are lost at system restart
    # this is meant redefine those methods the first time they are called
    def method_missing( method_sym, *args, &block )
      method_name = method_sym.to_s

      method_root = method_name.sub(/\+=$/, '').sub(/=$/, '')

      # TODO: evaluate whether this works in PostgreSQL
      extended_field = ExtendedField.find(:first, :conditions => "UPPER(label) = '#{method_root.upcase.gsub('_', ' ')}'")

      unless extended_field
        super
      else
        # if any of the extended field methods are called
        # we define them all
        self.class.define_methods_for(extended_field)

        # after the methods are defined, go ahead and call the method
        self.send(method_sym, *args, &block)
      end
    end

    def convert_extended_content_to_xml(params_hash)

        # Force a new instance of Bulder::XMLMarkup to be spawned
        xml(true)

        all_field_mappings.collect do |field_to_xml|

          # label is unique, whereas xml_element_name is not
          # thus we use label for our internal (topic.extended_content) storage of arbitrary attributes
          # xml_element_name is used for exported topics, such as oai/dc records
          field_name = field_to_xml.extended_field_label.downcase.gsub(/\s/, '_')

          # because we piggyback multiple, it doesn't have a ? method
          # even though it is boolean
          if field_to_xml.extended_field_multiple

            # we have multiple values for this field in the form
            # collect them in an outer tag
            # do an explicit key, so we end up with a hash
            xml.tag!("#{field_name}_multiple") do
              hash_of_values = params_hash[field_name]

              # Do not store empty values
              hash_of_values = hash_of_values ? hash_of_values.reject { |k, v| v.blank? } : nil

              if !hash_of_values.blank?
                hash_of_values.keys.sort.each do |key|

                  # Do not store empty values of multiples for choices.
                  unless params_hash[field_name][key].to_s.blank? || \
                        ( params_hash[field_name][key].is_a?(Hash) && params_hash[field_name][key].values.to_s.blank? )

                    xml.tag!(key) do
                      extended_content_field_xml_tag(
                        :xml => xml,
                        :field => field_name,
                        :value => params_hash[field_name][key],
                        :xml_element_name => field_to_xml.extended_field_xml_element_name,
                        :xsi_type => field_to_xml.extended_field_xsi_type,
                        :extended_field => field_to_xml.extended_field
                      )
                    end
                  end

                end
              else
                # this handles the case where edit has changed the item from one topic type to a sub topic type
                # and there isn't an existing value for this multiple
                # generates empty xml elements for the field
                key = 1.to_s
                xml.tag!(key) do
                    extended_content_field_xml_tag(
                      :xml => xml,
                      :field => field_name,
                      :value => '',
                      :xml_element_name => field_to_xml.extended_field_xml_element_name,
                      :xsi_type => field_to_xml.extended_field_xsi_type,
                      :extended_field => field_to_xml.extended_field
                    )
                end
              end
            end
          else
            extended_content_field_xml_tag(
              :xml => xml,
              :field => field_name,
              :value => params_hash[field_name],
              :xml_element_name => field_to_xml.extended_field_xml_element_name,
              :xsi_type => field_to_xml.extended_field_xsi_type,
              :extended_field => field_to_xml.extended_field
            )
          end

        # TODO: For some reason a bunch of duplicate extended fields are created. Work out why.
        end.flatten.uniq.join("\n")
      end

      def convert_xml_to_extended_fields_hash
        xml_attributes_without_position
      end

      def convert_xml_to_key_value_hash
        options = {
          "contentkey"  => "value",
          "forcearray"  => false,
          "noattr"      => true
        }

        XmlSimple.xml_in("<dummy>#{extended_content}</dummy>", options).map do |key, value|
          recursively_convert_values(key, value)
        end
      end

      def recursively_convert_values(key, value = nil)
        if value.is_a?(Hash) && !value.empty?
          [key, array_of_values(value)]
        else
          [key, value.empty? ? nil : value.to_s]
        end
      rescue
        raise "Error processing {#{key.inspect} => #{value.inspect}}"
      end

      def array_of_values(hash)
        hash.map do |k, v|
          if v.is_a?(Hash) && !v.empty?
            v.size == 1 ? array_of_values(v).flatten : array_of_values(v)
          else
            v.to_s
          end
        end
      end

      # All available extended field mappings for the given item.
      # Overloaded in Topic model (special case with hierarchical TopicTypes)
      def all_field_mappings
        ContentType.find_by_class_name(self.class.name).content_type_to_field_mappings
      end

      # Validation methods..
      def validate
        all_field_mappings.each do |mapping|

          field = mapping.extended_field

          if field.multiple?
            value_pairs = extended_content_pairs.select { |k, v| k == field.label_for_params + "_multiple" }

            # Remember to reject anything we use for signalling.
            values = value_pairs.map { |k, v| v }.flatten
            validate_extended_content_multiple_values(mapping, values)
          else
            value_pairs = extended_content_pairs.select { |k, v| k == field.label_for_params }
            values = value_pairs.map { |k, v| v }
            validate_extended_content_single_value(mapping, values.first)
          end
        end
      end

      # Generic validation methods
      def validate_extended_content_single_value(extended_field_mapping, value)
        # Handle required fields here..
        if extended_field_mapping.required && value.blank? && \
          extended_field_mapping.extended_field.ftype != "checkbox"

          errors.add_to_base("#{extended_field_mapping.extended_field.label} cannot be blank")
        else

          # Otherwise delegate to specialized method..
          if message = send("validate_extended_#{extended_field_mapping.extended_field.ftype}_field_content".to_sym, \
            extended_field_mapping, value)

            errors.add_to_base("#{extended_field_mapping.extended_field_label} #{message}")
          end

        end
      end

      def validate_extended_content_multiple_values(extended_field_mapping, values)

        if extended_field_mapping.required && values.all? { |v| v.to_s.blank? } && \
          extended_field_mapping.extended_field.ftype != "checkbox"

          errors.add_to_base("#{extended_field_mapping.extended_field.label} must have at least one value")
        else

          # Delete to specialized method..
          error_array = values.map do |v|
            send("validate_extended_#{extended_field_mapping.extended_field.ftype}_field_content".to_sym, \
              extended_field_mapping, v.to_s)
          end

          error_array.compact.each do |e|
            errors.add_to_base("#{extended_field_mapping.extended_field.label} #{e}")
          end
        end
      end

      # Specialized validation methods below..

      def validate_extended_checkbox_field_content(extended_field_mapping, value)
        return nil if value.blank?

        unless value =~ /^((Y|y)es|(N|n)o)$/
          "must be a valid checkbox value (Yes or No)"
        end
      end

      def validate_extended_radio_field_content(extended_field_mapping, value)

        # Unsure right now how to handle radio fields. A single radio field is not of any use in the context
        # of extended fields/content.
        nil
      end

      def validate_extended_date_field_content(extended_field_mapping, value)

        # Allow nil values. If this is required, the nil value will be caught earlier.
        return nil if value.blank?

        unless value =~ /^[0-9]{4}\-[0-9]{2}\-[0-9]{2}$/
          "must be in the standard date format (YYYY-MM-DD)"
        end
      end

      def validate_extended_text_field_content(extended_field_mapping, value)

        # We accept pretty much any value for text fields
        nil
      end

      def validate_extended_textarea_field_content(extended_field_mapping, value)

        # We accept pretty much any value for text fields
        nil
      end

      def validate_extended_choice_field_content(extended_field_mapping, values)
        # Allow nil values. If this is required, the nil value will be caught earlier.
        return nil if values.blank?

        if !values.is_a?(Array) && !extended_field_mapping.extended_field.choices.map { |c| c.value }.member?(values)
          "must be a valid choice"
        elsif !values.reject { |v| v.blank? }.all? { |v| extended_field_mapping.extended_field.choices.map { |c| c.value }.member?(v) }
          "must be a valid choice"
        end
      end

      def validate_extended_autocomplete_field_content(extended_field_mapping, values)
        # Allow nil values. If this is required, the nil value will be caught earlier.
        return nil if values.blank?

        if !values.is_a?(Array) && !extended_field_mapping.extended_field.choices.map { |c| c.value }.member?(values)
          "must be a valid choice"
        elsif !values.reject { |v| v.blank? }.all? { |v| extended_field_mapping.extended_field.choices.map { |c| c.value }.member?(v) }
          "must be a valid choice"
        end
      end

      def validate_extended_map_field_content(extended_field_mapping, values)
        # Allow nil values. If this is required, the nil value will be caught earlier.
        return nil if values.blank?

        unless values.is_a?(Array)
          "is not an array of latitude and longitude. Why?"
        end
      end

  end
end
