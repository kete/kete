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
      # open our agencies/records.xml and work through each one, looking up its predecessor and successory agencies
      # and update it with them
      agencies_xml = Nokogiri::XML File.open(RAILS_ROOT + '/imports/' + 'agencies/records.xml')
      agencies_xml.xpath('dataroot/XML2').each do |record|
        # look up the matching topic based on Code
        agency_code = record.xpath('Code').inner_text
        ext_field_data = "<code xml_element_name=\"dc:identifier\">#{agency_code}</code>"
        this_agency_topic = Topic.find(:first, :conditions => "(extended_content like '%#{ext_field_data}%' OR private_version_serialized like '%#{ext_field_data}%')")
        p this_agency_topic.title if this_agency_topic

        updated = false
        ['Successor', 'Predecessor'].each do |pattern|
          xml_pattern = 'agency.' + pattern
          setter_method = pattern.downcase + '_agency' + '='

          pattern_code = record.xpath(xml_pattern).inner_text
          unless pattern_code.blank?
            ext_field_data = "<code xml_element_name=\"dc:identifier\">#{pattern_code}</code>"
            pattern_topic = Topic.find(:first, :conditions => "(extended_content like '%#{ext_field_data}%' OR private_version_serialized like '%#{ext_field_data}%')")

            if pattern_topic
              topic_url = url_for_dc_identifier(pattern_topic)
              value = { 'label' => pattern_code, 'value' => topic_url }

              this_agency_topic.send(setter_method, value)
              ContentItemRelation.new_relation_to_topic(pattern_topic, this_agency_topic) unless this_agency_topic.related_topics.include?(pattern_topic)

              p pattern + ' added: ' + pattern_code
              updated = true
            end

          end

          if updated
            this_agency_topic.save
          
            this_agency_topic.prepare_and_save_to_zoom
          end
        end
      end
    end
    desc 'Update an agency description with entry in table of contents for series.'
    task :update_description_with_toc => :environment do
      agencies = TopicType.find_by_name("Agency").topics
      agencies.each do |agency|
        series = agency.child_related_topics.find_all_by_topic_type_id(TopicType.find_by_name("Series").id)
        
        html = "<table><tr><th>Series</th><th>Date Range</th></tr>"

        series.each do |series|
          url = url_for_dc_identifier(series)
          html += "<tr><td><a href=\"#{url}\">#{series.title}</a></td><td>#{series.date_range}</td></tr>"
        end

        html += "</table>>"

        agency.description = agency.description + ' ' + html
        agency.save
      end
    end

  end

  namespace :series do
    desc 'Update an agency description with entry in table of contents for series.'
    task :update_agency_toc => :environment do
    end
  end
end
