# Requirements for XML conversion of extended fields
require 'rexml/document'
require 'builder'
require 'xmlsimple'

# ExtendedContent provides a way to access additional, extended content directly on a model. (ExtendedContent is included in all
# Kete content types.)
#
# Extended Content definitions are configured separately by users with ExtendedField records which are mapped to topic types or # content types via the TopicTypeToFieldMapping and ContentTypeToFieldMapping relationship models. So, the relationships between
# item classes and extended fields is something like AudioRecording -> ContentTypeToFieldMapping(s) -> ExtendedField. In the case
# of Topics the relations are Topic -> TopicType -> TopicTypeToFieldMapping(s) -> ExtendedField. Refer to the individual classes
# for more information.
#
# On the model, extended content can be accessed by the #extended_content_values accessor methods, and by the less efficient individual
# accessor methods for each field. Behind the scenes the data received as a Hash instance of values (or single value in the case
# of accessor methods) is stored into a particular XML data structure in the #extended_content attribute, which is present as a
# column in the item class's table.
#
# XML Schema
#
# Extended content is stored as XML in the #extended_content attribute in the model. There are several conventions for how the XML
# is represented, outlined below:
#
# Items with single values are stored simply as follows:
# <field_label>Value</field_label>
#
# Items with multiple values:
# <field_label_multiple><1><field_label>Value</field_label></1><2><field_label>Value 2</field_label></2></field_label_multiple>
#
# Choices with single values:
# <field_label><1>Value</1></field_label>
#
# Choices with multiple hierarchical values:
# <field_label><1>Value</1><2>Child of value</2></field_label>
#
# Choices with multiple hierarchical values AND multiple values (i.e. multiple different hierchical selections)
# <field_label_multiple><1><field_label><1>Value</1><2>Child of value</2></field_label></1> ..
#   <2><field_label><1>Value</1><2>Child of value</2></field_label></2></field_label_multiple>
#
# Label/Value variation:
# Values are often what we want to match when we are doing searches, etc. They are meant to be precise and can conform to technical rules
# (e.g. http://must_have_valid_protocol_and_domain/and/path/for/a_url/or/link/will/fail). However, they often NOT what we want to be human
# facing.  This is where a corresponding label may come in.
#
# For example, if I want to have an extended field for "Father" on the "Person" Topic Type that links to a URL about the person's father,
# I probably don't want to display "http://a_kete/site/topics/show/666-the-devil".  I probably want to display "The Devil!" and clicking
# on that takes me to the appropriate topic, i.e. the URL.
#
# The same can be said of forms.  The user probably only wants to choose "The Devil!" and not have to remember the exact URL to input.
# The Choice model, in conjunction with the ExtendedField model, handles this in "Choices (dropdown)" and "Choices (autocomplete)"
# extended field ftypes.  A choice may have a label (that the user sees) that is different from the value (that the admin assigns
# the choice, but end user doesn't see) that gets saved to extended_content.
#
# The problem is, how do you we get the label on the display side on an item's detail page when all that is submitted is the value?
#
# We would like label, if it is different from value, to travel with the value as it is used.
#
# 1. in forms, when value is different than label, we pass the form input value of "Label (Value)", unless otherwise handled (choices).
# 2. when processing the form input in our model, via this module, we know to split label and value using this convention
# 3. model.extended_content we store the corresponding xml like so:
#
# Items with single values are stored simply as follows:
# <field_label label="Label">Value</field_label>
#
# Items with multiple values:
# <field_label_multiple><1><field_label label="Label">Value</field_label></1><2><field_label label="Label">Value 2</field_label></2></field_label_multiple>
#
# Choices with single values:
# <field_label><1 label="Label">Value</1></field_label>
#
# Choices with multiple hierarchical values:
# <field_label><1 label="Label">Value</1><2 label="Label">Child of value</2></field_label>
#
# etc.
#
# NOTE: a label attribute isn't required for every value.  So something like this is valid:
#
# Choices with multiple hierarchical values:
# <field_label><1 label="Label">Value</1><2>Child of value</2></field_label>
#
# 4. when converting our xml to a hash for dealing with, we'll have a :label key/value pair.
#
# General notes on XML schema:
# XML element name for the OAI XML schema is stored in the xml_element_name attribute in the XML tag, for instance:
# <field_name xml_element_name="dc:description">value</field_name>
#
# OAI XML Schema
#
# The OAI XML Schema has a different representation to the internal XML schema.
# The main differences are:
#
# * Where an XML element name has been declared in the ExtendedField record, it is used as the tag name. For instance,
#   <field_name xml_element_name="dc:subject">value</field_name> in the internal XML is translated to
#   <dc:subject>value</dc:subject> in the OAI XML.
# * Where an XML element name is not given in the ExtendedField record, the whole tag is wrapped verbatim in a
#   dc:description tag. For instance, <field_name>value</field_name> translates to the following in the OAI XML schema:
#   <dc:description>\n<field_name>value</field_name>\n</dc:description>. Where multiple fields are missing XML element
#   names, they are all wrapped in a single dc:description tag.
# * For values relating to the Choice ftypes are present, these are delimited by colons. For instance, assuming that the
#   ftype on the ExtendedField record is a variation of Choice, a singular, single level selection would be represented
#   as follows: <dc:description>:choice value:</dc:description> (note the dc:description could be the field name wrapped
#   in a dc:description tag as mentioned in the point above in some cases. Where hierarchical selections are present, the
#   values are presented as follows <dc:description>:first choice:child of first choice:</dc:description>.

module ExtendedContent
  CLASSES_WITH_SUMMARIES = ['Topic', 'Document']

  unless included_modules.include? ExtendedContent

    include ExtendedContentHelpers

    # DEPRECATED
    # Provide an instance of Nokogiri::XML::Builder.new for creating the XML representation
    # stored in each item's extended content attribute.
    def xml(force_new = false)
      raise 'ERROR: xml method not needed. The call to this method should be replaced!'
      if force_new
        @builder_xml = Nokogiri::XML::Builder.new
      else
        @builder_xml ||= Nokogiri::XML::Builder.new
      end
    end

    # Return key value pairs of extended field content stored in #extended_content.
    #
    # Example:
    # An item with extended fields mapped with 'Field one' with a single value ('value for field one') and 'Field two' with
    # multiple values ('first value for field two', 'second value for field two', would return the following:
    # [['field_one', 'value for field one'], ['field_two', ['first value for field two', 'second value for field two']]]
    def extended_content_pairs
      convert_xml_to_key_value_hash
    end

    # Return a hash of values for extended field content
    #
    # Example:
    # If the following XML is in #extended_content: <some_tag xml_element_name="dc:something">something</some_tag>
    # <some_other_tag xml_element_name="dc:something_else">something_else</some_other_tag>, then the following would be
    # returned:
    # { "some_tag" => { "xml_element_name" => "dc:something", "value" => "something" }, "some_other_tag" => {
    # "xml_element_name" => "dc:something_else", "value" => "something_else" } }
    def extended_content_values
      convert_xml_to_extended_fields_hash
    end

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
      extended_content_hash = xml_attributes_without_position

      ordered_hash = {}
      position = 1

      form_fields = all_field_mappings

      if form_fields.size > 0
        form_fields.each do |extended_field_mapping|
          f_id = extended_field_mapping.extended_field_label.downcase.gsub(/\s/, '_')
          f_multiple = "#{f_id}_multiple"
          f_key = f_multiple

          # because of the structure extended content xml
          # we try multiple field name first
          field_value = extended_content_hash[f_multiple]
          # if we didn't match a multiple
          # then we are all clear to use the plain f_id
          if field_value.blank?
            field_value = extended_content_hash[f_id]
            f_key = f_id
          end

          if field_value.present?
            ordered_hash[position.to_s] = { f_key => field_value }
            position += 1
          end
        end
      end

      ordered_hash
    end

    # Refer to #xml_attributes.
    alias extended_content_ordered_hash xml_attributes

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
      hash = XmlSimple.xml_in("<dummy>#{add_xml_fix(extended_content)}</dummy>", 'contentkey' => 'value', 'forcearray' => false)
      remove_xml_fix(hash)
    end

    # Checks whether the current class (Topic, AudioRecording, etc) can have a short summary
    # NOTE: Unsure how this relates to extended content
    def can_have_short_summary?
      CLASSES_WITH_SUMMARIES.include?(self.class.name)
    end

    # Returns extended content values in a structured format for modification.
    # Together with #structured_extended_content=, this method can be used to modify extended content values internally.
    # Example: #=> { "field_name" => [['value'], ..] }
    # From the example above you should be able to see that where multiple values are present, these are provided as
    # successive items in the values array. The values are doubly nested to allow for hierarchical choices, for example:
    # #=> { "field_name" => [['first value', 'child of first value'], ['second choice selection']] }
    def structured_extended_content
      convert_xml_to_key_value_hash.inject({}) do |hash, field|
        field_name = field.delete(field.first)
        field_name_root = field_name.gsub('_multiple', '')

        # Grab the extended field for this field name
        extended_field = all_fields.find { |ef| field_name_root == ef.label_for_params }

        # if there isn't a corresponding extended_field, this is orphaned data, ignore
        # otherwise add it to the hash
        unless extended_field.blank?

          # We need to handle singular and multiple field values separate as they come out in different formats.
          if field_name.include?('_multiple')

            # At this stage we expect to have something like:
            # ['field_name_multiple', [['value 1'], ['value 2']]

            # So we can assume the first element in the array is the field name, and the remainder are the values,
            # already in the correct format. 'field' now contains what we want because we've removed the first
            # element (the name) above. It is nested an extra level, through.
            values = field.first

            field_name = field_name_root
          elsif ['map', 'map_address'].member?(extended_field.ftype)
            values = field.first # pull the hash out of the array it's been put into
          else

            # For singular values we expect something like:
            # ['field_name', 'value'] (in normal cases), or [['field_name', 'value']] (in the case of hierarchical choices)
            # So, we need to adjust the format to be consistent with the expected output..
            values = field.first.is_a?(Array) || value_label_hash?(field.first) ? field : [field]
          end

          hash[field_name] = values
        end

        hash
      end
    end

    # turns choice hashes into arrays
    def hashes_to_arrays(values)
      values.collect do |value|
        if value.is_a?(Hash) && value.keys.include?('value') && value.keys.include?('label')
          if value['label'] == value['value']
            value['label']
          else
            value
          end
        elsif value.is_a?(Array)
          hashes_to_arrays(value)
        else
          value
        end
      end
    end

    # Sets extended content values based on those provided to the method in a standardized hash format.
    # The hash format accepted is identical to that provided by #structured_extended_content; the methods are intended
    # to be used together.
    # Below is an example of a valid hash
    # #=> { "text_field" => [['value'], ['second selected value']],
    #       "choice" => [['first choice', 'child of first choice - hierarchical selection'], ['second choice']] }
    # Note especially that the nesting of values is standardized and consistent. In the example above, both "text_field"
    # and "choice" accept multiple values. In the "choice" values, the first choice contains a hierachical selection.
    # An example of a basic field that accepts a single text value is below:
    # #=> { "basic_text_field" => [['value for field']] }
    # Underneath the hood, conversion is done by #extended_content_values=, the same way it is handled normally
    # for POSTed params.
    def structured_extended_content=(hash)
      hash_for_conversion =
        hash.inject({}) do |result, field|
          # Extract the name of the field
          field_param_name = field.delete(field.first)

          # Grab the extended field for this field name
          extended_field = all_fields.find { |ef| field_param_name == ef.label_for_params }

          # Remove the extra level of nesting left after removing the first of two elements
          field = field.first

          # in some cases, field may be nil, but needs to be nil wrapped in an array
          field = [nil] if field.nil?

          if ['map', 'map_address'].member?(extended_field.ftype)
            result[field_param_name] = convert_value_from_structured_hash(field, extended_field)

          # if we are dealing with a multiple topic type
          # we need to do things a bit differently
          elsif extended_field.ftype == 'topic_type' && extended_field.multiple?
            index = 1
            result[field_param_name] =
              field.inject({}) do |multiple, value|
                unless value.blank?
                  multiple[index.to_s] = value
                  index += 1
                end
                multiple
              end
          elsif ['autocomplete', 'choice'].member?(extended_field.ftype)
            if field.size > 1
              # We're dealing with a multiple field value.
              result[field_param_name] =
                field.inject({}) do |multiple, value|
                  multiple[(field.index(value) + 1).to_s] = convert_value_from_structured_hash(value, extended_field)
                  multiple
                end
            else
              result[field_param_name] = convert_value_from_structured_hash(field, extended_field)
            end
          else
            if (extended_field.multiple && field.size > 0) || field.size > 1
              # We're dealing with a multiple field value.
              result[field_param_name] =
                field.inject({}) do |multiple, value|
                  multiple[(field.index(value) + 1).to_s] = convert_value_from_structured_hash(value, extended_field)
                  multiple
                end
            else
              result[field_param_name] = convert_value_from_structured_hash(field, extended_field)
            end
          end

          result
        end

      # Pass the pseudo params hash for conversion using the usual methods.
      self.extended_content_values = hash_for_conversion
    end

    # Convert a value into a suitable param structure. This is factored out to handle changing multiple choice selections/hierarchies
    # into the necessary indexed key structure, i.e.
    # convert_value_from_structured_hash(['value']) # => 'value'
    # convert_value_from_structured_hash(['value', 'child of value']) # => { "1" => "value", "2" => "child of value" }
    # convert_value_from_structured_hash({ :coords => '123,123' }) # => { :coords => '123,123' }
    def convert_value_from_structured_hash(value_array, extended_field)
      # If the extended field is a choice, make sure it's values properly indexed in XML.
      if ['autocomplete', 'choice'].member?(extended_field.ftype)
        # gives some flexibility when value is being swapped in from add-ons (read translations)
        value_array = [value_array] if value_array.is_a?(String)

        value_array.flatten!
        value_array.inject({}) do |hash, value|
          value_index = (value_array.index(value) + 1).to_s
          if !value.is_a?(Hash)
            value = value.to_s
          elsif value_label_hash?(value) && value['label'] == value['value']
            value = value['label']
          end

          hash[value_index] = value
          hash
        end
      elsif ['map', 'map_address'].member?(extended_field.ftype)
        value_array.is_a?(Array) ? value_array.first : value_array
      elsif extended_field.ftype == 'year'
        value_array = value_array.first if value_array.is_a?(Array)
        value_array = value_array.first if value_array.is_a?(Array) && !extended_field.multiple?
        value_array
      elsif value_array.is_a?(Array) && value_label_hash?(value_array.first)
        value_array
      else
        value_array.to_s
      end
    end

    private :convert_value_from_structured_hash

    # Read a value for a singular extended field from extended content XML.
    # Singular values are returned as a raw String, multiples as an array of Strings.
    # Where hierarchical choices are present, they are joined with " -> ".
    # I.e. when selecting a singular choice value where hierarchical choices have been selected,
    # you would expect "parent choice -> child choice".
    def reader_for(extended_field_element_name, field = nil)
      values = structured_extended_content[extended_field_element_name].to_a
      values = hashes_to_arrays(values).to_a
      if values.size == 1
        if field && field.ftype == 'year'
          values = values.first if values.is_a?(Array)
          values = values.first if values.is_a?(Array) && !field.multiple?
          values
        else
          value = values.first
          if value.is_a?(Array)
            if value.size == 1
              value = value.first
            end
          end
          values = value
        end
      end
      values
    end

    # Replace the value of an extended field's content.
    # This works by retrieving the data from XML, replacing the value, then writing the entire XML content back
    # to the XML string kept in #extended_content.
    def replace_value_for(extended_field_element_name, value, field = nil)
      # Fetch the existing data from XML
      sandpit_data = structured_extended_content

      # Replace the value we're changing
      # The value needs to be nested to form an array if necessary, since we ALWAYS pass in an array.
      if field.is_a_choice? && !value.is_a?(Array)
        value = [[value]]
      elsif (field.is_a_choice? && !value.first.is_a?(Array)) || !value.is_a?(Array)
        value = [value]
      end

      # if field is a choice and users may add new choices
      # and value contains something that isn't current found as a choice, create a corresponding choice
      if field.is_a_choice?
        # peel off the array nesting
        # to get to nested values
        value.flatten.each do |v|
          # TODO: this has been copied and modified from extended_content_helpers, DRY up
          # one difference is that this assumes no parent
          # since we flatten

          # splits a value into label and value
          # if it has a pattern of "label (value)"
          # useful for auto populated pseudo choices (all topic types available as choices)
          # where label may not be unique
          # and case where user may contribute a new choice
          parts = v.match(/(.+)\(([^\(\)]+)\)\Z/).to_a
          # l is label for this particular value
          l = nil
          unless parts.blank?
            l = parts[1].chomp(' ')
            v = parts[2]
          end

          matching_choice = Choice.matching(l, v)

          # Handle the creation of new choices where the choice is not recognised.
          if !matching_choice && %w(autocomplete choice).include?(field.ftype) && field.user_choice_addition?
            parent = Choice.find(1)

            begin
              choice = Choice.create!(value: v, label: l)
              choice.move_to_child_of(parent)
              choice.save!
              field.choices << choice
              field.save!
            rescue
              next
            end
          end
        end
      end

      sandpit_data[extended_field_element_name] = value

      # Write the data back to XML
      self.structured_extended_content = sandpit_data

      value
    end

    # Append a value to an extended field's content.
    # Used for string concatenatation
    # I.e.  topic.field_name = "first"
    #       => "first"
    #       topic.field_name += "second"
    #       => "firstsecond"
    def append_value_for(extended_field_element_name, additional_value, field = nil)
      current_value = structured_extended_content[extended_field_element_name]

      raise "Cannot concatenate a value as #{extended_field_element_name} already has multiple values." if \
        current_value.size > 1

      unless additional_value.blank?
        replace_value_for(extended_field_element_name, current_value.to_s + additional_value.to_s, field)
      end

      # Confirm new values
      reader_for(extended_field_element_name, field)
    end

    # Append a new multiple value to an extended field which supports multiple values
    # In contrast to append_value_for, this adds a value to an array on the attribute, instead of concatenating
    # to the current string.
    def append_new_multiple_value_for(extended_field_element_name, additional_value, field = nil)
      raise "Cannot add a new multiple value on #{extended_field_element_name} as it is not a multiple value field." \
        unless field.nil? || field.multiple?

      # to_a allows for current_values to be an empty array (and thus work with + operator)
      # rather than nil
      current_values = structured_extended_content[extended_field_element_name].to_a
      additional_value = [[additional_value]]

      unless additional_value.blank?
        replace_value_for(extended_field_element_name, current_values + additional_value, field)
        # Confirm new values
        reader_for(extended_field_element_name, field)
      end
    end

    def all_fields
      @all_fields ||= all_field_mappings.map { |mapping| mapping.extended_field }.flatten
    end

    private

    # we want dynamic setters (= and +=) and getters for our extended fields
    # we dynamically extend the model with method definitions when a new field_mapping is added
    # triggered by the after_create and after_destroy methods in the join model

    # first up, define the three skeleton methods
    # def self.define_methods_for(extended_field)
    #   base_method_name = extended_field.label_for_params
    #
    #   define_method(base_method_name) do
    #     reader_for(base_method_name)
    #   end
    #
    #   define_method(base_method_name + '=') do |value|
    #     replace_value_or_create_element_for(base_method_name, value)
    #   end
    #
    #   define_method(base_method_name + '+=') do |value|
    #     append_value_for(base_method_name, additional_value)
    #   end
    # end
    #
    # def self.undefine_methods_for(extended_field)
    #   base_method_name = extended_field.label_for_params
    #
    #   ['', '=', '+='].each do |method_operator|
    #     remove_method(base_method_name + method_operator)
    #   end
    # end

    # Refining method_missing. Handle requests for extended content accessor methods
    # Since we are not handling extended content using attribute accessors extremely frequently,
    # method_missing should be able to handle all requests to these methods.
    def method_missing(symbol, *args, &block)
      # Construct some information we need
      method_name = symbol.to_s
      method_root = method_name.gsub(/[^\w]/, '')

      # all_fields : Get all extended fields from mappings. Since we're going to be accessing this construct when
      # setting values anyhow, we hitting it here shouldn't be too much of a performance penalty, at least
      # when compared to writing out the XML.

      # If we can find the field on this item..
      if (field = all_fields.find { |field| method_root == field.label_for_params }) && !field.blank?

        # If we're sending a single argument/value, don't send it as an array.
        args = args.size == 1 ? args.first : args

        # Run one of the generic methods as appropriate
        case method_name
        when /\+=$/
          field.multiple? ? append_new_multiple_value_for(method_root, args, field) : append_value_for(method_root, args, field)
        when /=$/
          replace_value_for(method_root, args, field)
        else
          reader_for(method_root, field)
        end
      else

        # Otherwise, forward the message request to the usual suspects
        super
      end
    end

    # usually when a new extended field is mapped to a content type or a topic type
    # corresponding methods are defined
    # however these dynamic methods definitions are lost at system restart
    # this is meant redefine those methods the first time they are called
    # def method_missing( method_sym, *args, &block )
    #   method_name = method_sym.to_s
    #
    #   method_root = method_name.sub(/\+=$/, '').sub(/=$/, '')
    #
    #   # TODO: evaluate whether this works in PostgreSQL
    #   extended_field = ExtendedField.find(:first, :conditions => "UPPER(label) = '#{method_root.upcase.gsub('_', ' ')}'")
    #
    #   unless extended_field
    #     super
    #   else
    #     # if any of the extended field methods are called
    #     # we define them all
    #     self.class.define_methods_for(extended_field)
    #
    #     # after the methods are defined, go ahead and call the method
    #     self.send(method_sym, *args, &block)
    #   end
    # end

    attr_writer :allow_nil_values_for_extended_content

    def allow_nil_values_for_extended_content
      @allow_nil_values_for_extended_content.nil? ? true : @allow_nil_values_for_extended_content
    end

    def convert_extended_content_to_xml(params_hash)
      return '' if params_hash.blank?

      builder = Nokogiri::XML::Builder.new
      builder.root do |xml|
        all_field_mappings.collect do |field_to_xml|
          # we should not generate extended field content for mappings that
          # are private_only but are submitted for a public version
          next if field_to_xml.private_only? && respond_to?(:private) && !private?

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
            xml.safe_send("#{field_name}_multiple") do
              hash_of_values = params_hash[field_name]

              # Do not store empty values
              hash_of_values = hash_of_values ? hash_of_values.reject { |k, v| v.blank? } : nil

              if !hash_of_values.blank?
                hash_of_values.keys.sort.each do |key|
                  value = params_hash[field_name][key]

                  # for the year extended field types, skip unless the value is present
                  next if value.is_a?(Hash) && value['circa'] && value['value'].blank?

                  # Do not store empty values of multiples for choices.
                  unless value.to_s.blank? || (value.is_a?(Hash) && value.values.to_s.blank?)
                    xml.safe_send(key) do
                      extended_content_field_xml_tag(
                        xml: xml,
                        field: field_name,
                        value: value,
                        xml_element_name: field_to_xml.extended_field_xml_element_name,
                        xsi_type: field_to_xml.extended_field_xsi_type,
                        extended_field: field_to_xml.extended_field
                      )
                    end
                  end
                end
              else
                # this handles the case where edit has changed the item from one topic type to a sub topic type
                # and there isn't an existing value for this multiple
                # generates empty xml elements for the field
                key = 1.to_s
                xml.safe_send(key) do
                  extended_content_field_xml_tag(
                    xml: xml,
                    field: field_name,
                    value: '',
                    xml_element_name: field_to_xml.extended_field_xml_element_name,
                    xsi_type: field_to_xml.extended_field_xsi_type,
                    extended_field: field_to_xml.extended_field
                  )
                end
              end
            end
          else
            # this handles the case where edit has changed the item from one topic type to a sub topic type
            # and there isn't an existing value
            # generates empty xml element for the field
            final_value = params_hash[field_name].nil? ? '' : params_hash[field_name]

            # for the year extended field types, skip unless the value is present
            next if final_value.is_a?(Hash) && final_value['circa'] && final_value['value'].blank?

            extended_content_field_xml_tag(
              xml: xml,
              field: field_name,
              value: final_value,
              xml_element_name: field_to_xml.extended_field_xml_element_name,
              xsi_type: field_to_xml.extended_field_xsi_type,
              extended_field: field_to_xml.extended_field
            )
          end
        end

        # OLD_KETE_TODO: For some reason a bunch of duplicate extended fields are created. Work out why.
      end

      builder.to_stripped_xml
    end

    def convert_xml_to_extended_fields_hash
      xml_attributes_without_position
    end

    def convert_xml_to_key_value_hash
      options = {
        'contentkey'  => 'value',
        'forcearray'  => false,
        'noattr'      => false
      }

      XmlSimple.xml_in("<dummy>#{add_xml_fix(extended_content)}</dummy>", options).map do |key, value|
        recursively_convert_values(key, value)
      end
    end

    def recursively_convert_values(key, value = nil)
      if value.is_a?(Hash) && !value.empty?
        value = array_of_values(value).reject { |questionable_value| questionable_value.nil? }
        value = value.first if value.size == 1
        [key, value.blank? ? nil : value]
      else
        [key, value.blank? ? nil : value.to_s]
      end
    rescue
      raise "Error processing {#{key.inspect} => #{value.inspect}}"
    end

    def array_of_values(hash)
      # there is one instant where we just want to return the hash
      # if it has a label, we want a hash of label and value
      if value_label_hash?(hash) || hash.keys.include?('circa')
        hash.keys.each { |key| hash.delete(key) unless %w(value label circa).include?(key) }
        return [hash]
      end

      # we have to use the no_map key here because its the only constant one (0|1)
      # however, we need to fallback to coords incase we are working with legacy data
      # the rest can be left out which causes problems when saving items
      return [hash] if hash.keys.include?('no_map') || hash.keys.include?('coords') # map or map_address

      hash.map do |k, v|
        # skip special keys
        next if k == 'xml_element_name'

        if v.is_a?(Hash) && !v.empty?
          if value_label_hash?(v)
            v
          else
            array_of_values(v).flatten.compact
          end
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
          value_pairs = extended_content_pairs.select { |k, v| k == field.label_for_params + '_multiple' }

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
      no_map_enabled = (%w(map map_address).member?(extended_field_mapping.extended_field.ftype) && (!value || value['no_map'] == '1'))
      no_year_provided = (extended_field_mapping.extended_field.ftype == 'year' && (!value || value['value'].blank?))
      if extended_field_mapping.required &&
         (value.blank? || no_map_enabled || no_year_provided) &&
         extended_field_mapping.extended_field.ftype != 'checkbox'

        errors.add_to_base(I18n.t(
                             'extended_content_lib.validate_extended_content_single_value.cannot_be_blank',
                             label: extended_field_mapping.extended_field.label
        )) unless \
          extended_field_mapping.extended_field.ftype != 'year' && \
          xml_attributes_without_position[extended_field_mapping.extended_field.label_for_params].nil? && \
          allow_nil_values_for_extended_content

      else

        # Otherwise delegate to specialized method..
        if message = send(
          "validate_extended_#{extended_field_mapping.extended_field.ftype}_field_content".to_sym, \
          extended_field_mapping, value
        )

          errors.add_to_base(message)
        end

      end
    end

    def validate_extended_content_multiple_values(extended_field_mapping, values)
      all_values_blank =
        values.all? do |v|
          v = v['value'] if v.is_a?(Hash) && v['value']
          v.to_s.blank?
        end

      if extended_field_mapping.required && all_values_blank && \
         extended_field_mapping.extended_field.ftype != 'checkbox'

        errors.add_to_base(I18n.t(
                             'extended_content_lib.validate_extended_content_multiple_values.need_at_least_one',
                             label: extended_field_mapping.extended_field.label
        )) unless \
          xml_attributes_without_position[extended_field_mapping.extended_field.label_for_params + '_multiple'].nil? && \
          allow_nil_values_for_extended_content

      else

        # Delegate to specialized method..
        error_array =
          values.map do |v|
            # if label is included, you get back a hash for value
            v = v['value'] if v.is_a?(Hash) && v['value'] && extended_field_mapping.extended_field.ftype != 'year'

            v = v.to_s unless extended_field_mapping.extended_field.ftype == 'year'

            send(
              "validate_extended_#{extended_field_mapping.extended_field.ftype}_field_content".to_sym, \
              extended_field_mapping, v
            )
          end

        error_array.compact.each do |error|
          errors.add_to_base(error)
        end
      end
    end

    # # Specialized validation methods below..

    def validate_extended_checkbox_field_content(extended_field_mapping, value)
      return nil if value.blank?

      unless value =~ /^((Y|y)es|(N|n)o)$/
        I18n.t(
          'extended_content_lib.validate_extended_checkbox_field_content.must_be_valid',
          label: extended_field_mapping.extended_field_label
        )
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
        I18n.t(
          'extended_content_lib.validate_extended_date_field_content.must_be_valid',
          label: extended_field_mapping.extended_field_label
        )
      end
    end

    # The year field value is passed in as a hash, { :value => 'something', :circa => '1' }
    def validate_extended_year_field_content(extended_field_mapping, values)
      # Allow nil values. If this is required, the nil value will be caught earlier.
      return nil if values.blank?
      # the values passed in should form an array
      return I18n.t(
        'extended_content_lib.validate_extended_year_field_content.not_a_hash',
        label: extended_field_mapping.extended_field_label,
        class: values.class.name, value: values.inspect
      ) unless values.is_a?(Hash)
      # allow the value to be blank
      return nil if values['value'].blank?
      # verify that we have a proper formatted value (YYYY)
      unless values['value'] =~ /^[0-9]{4}$/
        I18n.t(
          'extended_content_lib.validate_extended_year_field_content.must_be_valid',
          label: extended_field_mapping.extended_field_label
        )
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

      valid_choice_values = extended_field_mapping.extended_field.choices.collect { |c| c.value }

      # when labels are passed back, values may be a hash
      # handle array of hashes below when we are dealing with multiples
      values = values['value'] if values.is_a?(Hash) && values['value']

      # make everything everything an array, so we can deal with it uniformly
      # strip blank values, while we are at it
      values_array =
        values.to_a.reject { |v| v.blank? }.collect do |v|
          if v.is_a?(Hash)
            v['value']
          else
            v
          end
        end

      if !values_array.all? { |v| valid_choice_values.member?(v) }
        I18n.t(
          'extended_content_lib.validate_extended_choice_field_content.must_be_valid',
          label: extended_field_mapping.extended_field_label
        )
      end
    end

    def validate_extended_autocomplete_field_content(extended_field_mapping, values)
      validate_extended_choice_field_content(extended_field_mapping, values)
    end

    def validate_extended_topic_type_field_content(extended_field_mapping, value)
      # Allow nil values. If this is required, the nil value will be caught earlier.
      return nil if value.blank?

      # when labels are passed back, values may be a hash wrapped in an array
      if value.is_a?(Array)
        value_hash = value.first if value.size == 1
        value = value_hash['value'] if value_hash.is_a?(Hash) && value_hash['value']
      elsif value.is_a?(Hash) && value['value']
        value = value['value']
      end

      # this will tell us whether there is a matching topic
      topic = Topic.find_by_id(value.split('/').last.to_i, select: 'topic_type_id')

      # if this is nil, we were unable to find a matching topic
      return I18n.t(
        'extended_content_lib.validate_extended_topic_type_field_content.no_such_topic',
        label: extended_field_mapping.extended_field_label
      ) unless topic

      parent_topic_type = TopicType.find(extended_field_mapping.extended_field.topic_type.to_i)
      valid_topic_type_ids = parent_topic_type.full_set.collect { |topic_type| topic_type.id }

      unless valid_topic_type_ids.include?(topic.topic_type_id)
        I18n.t(
          'extended_content_lib.validate_extended_topic_type_field_content.must_be_valid',
          label: extended_field_mapping.extended_field_label,
          topic_type: parent_topic_type.name
        )
      end
    end

    # XML does not allow tag names to begin with numbers so '<1></1>' is not
    # valid XML. The old Kete uses this format (somehow!) so we filter <1> to
    # <position_1> for XML conversion.
    def add_xml_fix(xml_ish)
      return nil if xml_ish.nil?
      xml_ish.gsub(/<(\/?)(\d+)>/, '<\1position_\2>')
    end

    def remove_xml_fix(in_hash)
      out_hash = {}

      in_hash.each do |k, v|
        new_k = tweaked_key(k)
        new_v = v.dup

        if new_v.kind_of?(Hash)
          out_hash[new_k] = remove_xml_fix(new_v)
        else
          out_hash[new_k] = new_v
        end
      end

      out_hash
    end

    def tweaked_key(k)
      if k =~ /\Aposition_(\d)+\z/
        $1 # special case: "position_1" -> "1"
      else
        k
      end
    end

  end
end
