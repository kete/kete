class ExtendedContentParser
  # ROB: This code is ripped from the oai_dc_xml_dc_extended_content() and oai_dc_xml_for_field_dataset()
  #      in lib/extended_content_helpers.rb.
  #      It has been refactored to return values rather than add xml tags at some random point in a huge
  #      nested if/each/if/elsif/... trees.
  #
  #      The idea was to be a bit more easier to follow (it's only marginally better) but at least now
  #      this takes values and returns values with no side-effects in the middle.

  # Method for converting an content-item's extended_content field to key value pairs for
  # display (in RSS for instance).
  def self.key_value_pairs(item)
    # ROB:
    #
    # In existing oai-xml anonymous_pairs are shown inside <description></description> tags,
    # whereas non_anonymous_pairs are shown unwrapped.
    #
    # An example xml-tag could be:  <creation_date xml_element_name=\"dc:date\">16/04/2005</creation_date>
    # which generates the pair:     [ "dc:date", "16/04/2005" ]
    #
    # There are multiple different xml-tag formats.

    anonymous_pairs = []
    non_anonymous_pairs = []

    attribute_pairs = attribute_pairs_to_process(item)

    attribute_pairs.each do |field_key, field_data|
      anonymous_pairs << get_anonymous_key_value_pair(field_key, field_data)
      non_anonymous_pairs += get_non_anonymous_key_value_pairs(field_key, field_data)
    end

    [anonymous_pairs.compact, non_anonymous_pairs]
  end

  # ROB: complex example item.xml_attributes given by oai_dc_xml_dc_extended_content():
  #
  # {
  #    "text_field_multiple"=>{
  #       "2"=>{"text_field"=>{
  #          "xml_element_name"=>"dc:description",
  #          "value"=>"Value"
  #       }
  #       },
  #       "3"=>{
  #          "text_field"=>{
  #             "xml_element_name"=>"dc:description",
  #             "value"=>"Second value"
  #           }
  #       }
  #    },
  #    "married"=>"No",
  #    "check_boxes_multiple"=>{
  #      "1"=>{"check_boxes"=>"Yes"}
  #    },
  #    "vehicle_type"=>{
  #       "1"=>"Car",
  #       "2"=>"Coupé"
  #     },
  #    "truck_type_multiple"=>{
  #       "1"=>{
  #          "truck_type"=>{"1"=>"Lorry"}
  #       },
  #       "2"=>{
  #          "truck_type"=>{
  #              "1"=>"Tractor Unit",
  #              "2"=>"Tractor with one trailer"
  #          }
  #       }
  #    }
  # }

  def self.attribute_pairs_to_process(item)
    # item.extended_content like this:
    #
    #   <creator xml_element_name="dc:creator"></creator>
    #   <creation_date xml_element_name="dc:date"></creation_date>
    #   <user_reference xml_element_name="dc:identifier"></user_reference>

    fields_with_position_hash = item.xml_attributes

    # fields_with_position_hash like this:
    #
    # '1':
    #   creator:
    #     xml_element_name: dc:creator
    # '2':
    #   creation_date:
    #     xml_element_name: dc:date
    # '3':
    #   user_reference:
    # xml_element_name: dc:identifier

    sorted_fields_with_position_hash = fields_with_position_hash.sort_by { |k, v| k.to_s }.to_h
    fields_in_sorted_array = sorted_fields_with_position_hash.values

    # fields_in_sorted_array like this:
    #
    # - creator:
    #     xml_element_name: dc:creator
    # - creation_date:
    #     xml_element_name: dc:date
    # - user_reference:
    #     xml_element_name: dc:identifier

    attribute_pairs = []

    fields_in_sorted_array.each do |field_hash|
      field_hash =
        field_hash.reject do |field_key, field_data|
          # If this is google map contents, and no_map is '1', then do not use this data
          field_data.is_a?(Hash) && field_data['no_map'] && field_data['no_map'] == '1'
        end

      multi_instance_attributes = field_hash.select { |field_key, field_data| field_key =~ /_multiple$/  }
      regular_attributes =        field_hash.reject { |field_key, field_data| field_key =~ /_multiple$/  }

      multi_instance_attribute_pairs =
        multi_instance_attributes.flat_map do |field_key, field_data|
          field_data.map do |index, data|
            [field_key, data.values.first]
          end
        end

      regular_attribute_pairs =
        regular_attributes.map do |field_key, field_data|
          [field_key, field_data]
        end

      attribute_pairs = attribute_pairs + multi_instance_attribute_pairs + regular_attribute_pairs
    end

    attribute_pairs
  end

  def self.get_non_anonymous_key_value_pairs(field_key, data)
    key_value_pairs = []

    return key_value_pairs if data.is_a?(String)

    # We add a dc:date for 5 years before and after the value specified
    # We also convert the single YYYY value to a format Zebra can search against
    # Note: We use DateTime instead of just Date/Time so that we can get dates before 1900
    date_conversion_for_extended_content_hash!(data)

    if data.has_key?('value') && data.has_key?('circa') && data['circa'] == '1'
      five_years_before, five_years_after = (data['value'].to_i - 5), (data['value'].to_i + 5)
      key_value_pairs << ['dc:date', Time.zone.parse("#{five_years_before}-01-01").xmlschema]
      key_value_pairs << ['dc:date', Time.zone.parse("#{five_years_after}-12-31").xmlschema]
    end

    xml_value = flatten_any_extended_content_trees(data)
    # return key_value_pairs if xml_value.nil?

    # safe_send will drop the namespace from the element and therefore our dc elements
    # will not be parsed by zebra, only use safe_send on non-dc elements
    if data['xml_element_name'].present?
      xml_name = data['xml_element_name']

      unless data['xml_element_name'].include?('dc:')
        xml_name = escape_xml_name(xml_name)
      end

      key_value_pairs << [xml_name, xml_value]
    end

    key_value_pairs
  end

  def self.get_anonymous_key_value_pair(field_key, data)
    anonymous_fields = nil
    original_field_key = field_key.gsub(/_multiple/, '')

    if data.is_a?(String)
      # This works as expected
      # In the most simple case, the content is represented as "key" => "value", so use this directly
      # now if it's available.
      anonymous_fields = [original_field_key, data]

    else
      date_conversion_for_extended_content_hash!(data)

      xml_value = flatten_any_extended_content_trees(data)
      # return nil if xml_value.nil?

      # If data["xml_element_name"] exists this is handled by get_non_anonymous_key_value_pairs()
      if data['xml_element_name'].blank?
        anonymous_fields = [original_field_key, xml_value]
      end
    end

    anonymous_fields
  end

  def self.date_conversion_for_extended_content_hash!(data)
    if data.has_key?('value') && data.has_key?('circa')
      data['value'] = Time.zone.parse("#{data['value']}-01-01").xmlschema
    end
  end

  def self.flatten_any_extended_content_trees(data)
    # Example of what we might have in data at this point
    # {"xml_element_name"=>"dc:subject",
    #  "1"=>{"value"=>"Recreation", "label"=>"Sports & Recreation"},
    #  "2"=>"Festivals",
    #  "3"=>"New Year"}

    if data.has_key?('value')
      data['value']
    else
      # This means we're dealing with a second set of nested values, to build these now.
      data_for_values = data.reject { |k, v| k == 'xml_element_name' || k == 'label' }.values

      # By this stage, we may have either of the following:
      # [{:label => 'Something', :value => 'This'}, {:label => 'Another', :value => 'That'}]
      # ['This', 'That']
      # (or a combination of both). So in this case, lets collect the correct values before continuing
      data_for_values.collect! { |v| v.is_a?(Hash) && v['value'] ? v['value'] : v }.flatten.compact

      if data_for_values.empty?
        nil
      else
        ":#{data_for_values.join(":")}:"
      end
    end
  end

  # Make sure that the name is a valid XML name and escape common patterns (spaces to underscores)
  # to prevent import errors
  def self.escape_xml_name(name)
    name.to_s.gsub(/\W/, '_').gsub(/(^_*|_*$)/, '')
  end
end
