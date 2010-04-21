# lib/tasks/horizons.rake
#
# tools to help import horizons data, in addition to existing bulk import
#
# Walter McGinnis, 2009-10-29
#

require 'nokogiri'

namespace :horizons do

  namespace :agencies do

    desc 'Update agencies with their successor and predecessor agencies.'
    task :add_skipped_data => :environment do
      records = Nokogiri::XML File.open(RAILS_ROOT + '/imports/agencies/records.xml')
      agency_code_ext_field = ExtendedField.find_by_label('Agency Code')

      create_skipped_data_from({
        :records => records,
        :record_path => 'dataroot/XML2',
        :record_id_field => 'Code',
        :record_id_ext_field => agency_code_ext_field,
        :data => [
          [ 'agency.Predecessor', 'predecessor_agencies+=', agency_code_ext_field ],
          [ 'agency.Controlling', 'controlling_agencies+=', agency_code_ext_field ],
          [ 'agency.Controlled',  'agencies_controlled+=',  agency_code_ext_field ],
          [ 'agency.Successor',   'successor_agencies+=',   agency_code_ext_field ]
        ]
      })
    end

    desc 'Update an agency description with entry in table of contents for series.'
    task :update_description_with_toc => :environment do
      series_id = TopicType.find_by_name("Series").id
      agencies = TopicType.find_by_name("Agency").topics
      create_table_of_contents_between(agencies, series_id, [
        ['Series', :title],
        ['Start Date', :start_date],
        ['End Date', :end_date]
      ], :start_date)
    end

  end

  namespace :series do

    desc 'Update series with their successor, predecessor, and related series, and creator agencies.'
    task :add_skipped_data => :environment do
      records = Nokogiri::XML File.open(RAILS_ROOT + '/imports/series/records.xml')
      series_number_ext_field = ExtendedField.find_by_label('Series No')
      agency_code_ext_field = ExtendedField.find_by_label('Agency Code')

      create_skipped_data_from({
        :records => records,
        :record_path => 'dataroot/series',
        :record_id_field => 'Code',
        :record_id_ext_field => series_number_ext_field,
        :data => [
          [ 'related',     'related_series+=',    series_number_ext_field ],
          [ 'successor',   'subsequent_series+=', series_number_ext_field ],
          [ 'predecessor', 'previous_series+=',   series_number_ext_field ],
          [ 'agencies',    'creating_agency+=',   agency_code_ext_field ]
        ]
      })
    end

    desc 'Update the series descriptions with entry in table of contents of items.'
    task :update_description_with_toc => :environment do
      item_id = TopicType.find_by_name("Item").id
      series = TopicType.find_by_name("Series").topics
      create_table_of_contents_between(series, item_id, [
        ['Item', :title],
        ['Start Date', :start_date],
        ['End Date', :end_date]
      ], :start_date)
    end

  end

  namespace :items do

    desc 'Update items with their agency and series relations.'
    task :add_skipped_data => :environment do
      records = Nokogiri::XML File.open(RAILS_ROOT + '/imports/items/records.xml')
      item_key_ext_field = ExtendedField.find_by_label('Item Key')
      agency_code_ext_field = ExtendedField.find_by_label('Agency Code')
      series_number_ext_field = ExtendedField.find_by_label('Series No')

      create_skipped_data_from({
        :records => records,
        :record_path => 'dataroot/Item',
        :record_id_field => 'Key',
        :record_id_ext_field => item_key_ext_field,
        :data => [
          [ 'Agency', 'agencies+=', agency_code_ext_field   ],
          [ 'Series', 'series+=',   series_number_ext_field ]
        ]
      })
    end

  end

  private

  def find_topic_with_data_of(ext_field_data, extended_field)
    Topic.first(:conditions => build_conditions_for(ext_field_data, extended_field))
  end

  def build_conditions_for(ext_field_data, extended_field)
    ext_field_id = extended_field.label_for_params
    ext_field_xml_element_name = extended_field.xml_element_name
    ext_field_xml_element_name = " xml_element_name=\"#{ext_field_xml_element_name}\"" unless ext_field_xml_element_name.blank?
    ext_field_xml = "<#{ext_field_id}#{ext_field_xml_element_name}>#{ext_field_data}</#{ext_field_id}>".downcase
    "(LOWER(extended_content) LIKE '%#{ext_field_xml}%' OR LOWER(private_version_serialized) LIKE '%#{ext_field_xml}%')"
  end

  # Options:
  #  - :records              <- A Nokogiri parsed XML file
  #  - :record_path          <- XML Path to each record
  #  - :record_id_field      <- The XML field contain the record identifier
  #  - :record_id_ext_field  <- The extended field that links the record id to kete
  #  - :data                 <- An array of arrays
  #                             [0] -> xml field key
  #                             [1] -> extended field setter method
  #                             [2] -> extended field to find the related topic
  def create_skipped_data_from(options)
    options[:records].xpath(options[:record_path]).each do |record|

      record_id = record.xpath(options[:record_id_field]).inner_text
      record_topic = find_topic_with_data_of(record_id, options[:record_id_ext_field])

      if record_topic
        puts "Continuing: Found item with record key #{record_id.upcase}: topic #{record_topic.id}"
      else
        puts "Skipping: Item with record key #{record_id.upcase} not found"; next
      end

      updated = false

      options[:data].each do |xml_pattern, setter_method, related_id_ext_field|
        pattern_codes = record.xpath(xml_pattern).inner_text
        if pattern_codes.blank?
          puts "Skipping #{xml_pattern}: Value is blank"; next
        end

        # The code uses ý to separate multiple ones
        pattern_codes.split('ý').each do |pattern_code|
          if pattern_code.blank?
            puts "Skipping a #{xml_pattern}: Value is blank"; next
          end

          pattern_topic = find_topic_with_data_of(pattern_code, related_id_ext_field)
          if pattern_topic.blank?
            puts "Skipping #{xml_pattern}: Topic with pattern code of #{pattern_code.upcase} not found"; next
          end

          value = { 'label' => pattern_topic.title, 'value' => url_for_dc_identifier(pattern_topic) }

          # We should skip any topics that already have this data, to prevent entering it twice
          ext_field_label = (setter_method =~ /(\w+)/ && $1)
          if ext_field_label
            existing_pattern = /<#{ext_field_label}[^>]*>.*#{Regexp.escape(value['value'])}.*<\/#{ext_field_label}>/i
            next if record_topic.extended_content && record_topic.extended_content =~ existing_pattern
          end

          record_topic.send(setter_method, value)
          ContentItemRelation.new_relation_to_topic(record_topic, pattern_topic)

          puts "Added data for #{xml_pattern}: Relation from topic #{record_topic.id} to topic #{pattern_topic.id}"
          updated = true
        end
      end

      if updated
        record_topic.save
        record_topic.add_as_contributor(User.first)

        # We need to do a full rebuild at the end anyway, so skip this for now
        # record_topic.prepare_and_save_to_zoom
      end

    end
  end

  def create_table_of_contents_between(topics, contents_topic_type_id, columns = {}, sort_by = nil)
    topics.each do |topic|
      contents = topic.related_topics.select { |t| t.topic_type_id == contents_topic_type_id }.uniq

      next unless contents && contents.size > 0

      html = "<table>"

      html += "<tr>"
      # Create the table headers
      columns.each do |header, method|
        html += "<th>#{header}</th>"
      end
      html += "</tr>"

      # If sort_by is present, sort all contents by that. Rescue from any errors that occur
      unless sort_by.nil?
        contents = contents.sort_by do |s|
          value = s.send(sort_by) rescue nil
          value = value['value'] if value.is_a?(Hash) && value['value'].present?
          value || ''
        end
      end

      # Loop over contents
      contents.each do |content|
        html += "<tr>"
        # Create the table data
        columns.each do |header, method|
          if method.to_sym == :title
            url = url_for_dc_identifier(content)
            html += "<td><a href=\"#{url}\">#{content.title}</a></td>"
          else
            value = content.send(method) rescue nil
            value = value['value'] if value.is_a?(Hash) && value['value'].present?
            html += "<td>#{value || ''}</td>"
          end
        end
        html += "</tr>"
      end

      html += "</table>"

      topic.description = topic.description + ' ' + html
      topic.save
      topic.add_as_contributor(User.first)

      # We need to do a full rebuild at the end anyway, so skip this for now
      # topic.prepare_and_save_to_zoom
    end
  end

end
