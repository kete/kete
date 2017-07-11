# ROB:
#
# * If an item's tags/contributors/related_items is updated, or the item is changed
#   then it is considered changed.
# * We're not listing comments
# * udpated_since=date_string is handled by Ruby's DateTime.parse can handle (which
#   include iso8601, rfc3339, rfc2822, rfc822)
# * you can identify the objects by their <guid> tag which is the old <identifier> tag in <head>
# * the url schema has changed slightly so <dc:identifier> is slightly different

xml.instruct! :xml, version: '1.0' 
xml.rss('version' => '2.0', 'xmlns:dc' => 'http://purl.org/dc/elements/1.1/') do
  xml.channel do
    xml.title("#{SystemSetting.site_domain} #{@list_type} RSS Feed")
    xml.link "http://#{SystemSetting.site_url}"
    xml.description "#{SystemSetting.pretty_site_name} #{@list_type}s ordered by update-time. By default this shows items added/updated this month. "+
                    "An item is considered updated if it or it's tags/contributors/related_items has changed.\n"+
                    "\n"+
                    'To see earlier records use the udpated_since=date_string HTTP query-field (iso8601, rfc3339, rfc2822, rfc822)'
    xml.language 'en-nz'
    xml.ttl '60' 

    @items.each do |item|
      xml.item do
                # oai_dc_xml_oai_datestamp(xml)
                # oai_dc_xml_oai_set_specs(xml)
        xml.guid "rss:#{SystemSetting.site_domain}:#{item.basket.urlified_name}:#{item.class.name}:#{item.id}", isPermaLink: 'false'
        xml.title item.title        
        xml.pubDate item.updated_at.utc.xmlschema
        xml.link rss_link_for(item)

        xml.dc :identifier, rss_dc_identifier(item)
        xml.dc :title,      rss_dc_title(item)
        xml.dc :publisher,  rss_dc_publisher(item)

        rss_dc_description_array(item).each do |description_text|
          xml.dc :description do
            xml.cdata! description_text
          end
        end

        if item.is_a?(WebLink)
          xml.dc(:subject) {
            xml.cdata! item.url
          } 
        end

        # we do a dc:source element for the original binary file
        source_text = rss_dc_source_for_file(item)
        xml.dc :source, source_text if source_text

        if SystemSetting.add_date_created_to_item_search_record?
          xml.dc :date, rss_dc_date(item)
        end

        rss_dc_creators_array(item).each do |creator_string|
          xml.dc :creator, creator_string
        end
        
        rss_dc_contributors_array(item).each do |contributor_string|
          xml.dc :contributor, contributor_string
        end

        # all types at this point have an extended_content attribute
        anonymous_fields, non_anonymous_fields = rss_dc_extended_content(item)

        unless anonymous_fields.empty?
          # Build the anonymous fields that have no dc:* attributes.
          xml.dc(:description) do |inner_xml|
            anonymous_fields.each do |k, v|
              inner_xml.tag!(ExtendedContentParser.escape_xml_name(k), v)
            end
          end
        end

        non_anonymous_fields.each do |array|
          dc_label, value =  array[0], array[1]
          xml.tag! dc_label, value if value.present?
        end

        # related topics and items should have dc:subject elem here with their title
        rss_dc_relations_array(item).each do |relation_string|
          xml.dc :relation, relation_string
        end

        xml.dc :type, rss_dc_type(item)

        rss_tags_to_dc_subjects_array(item).each do |subject_string|
          xml.dc(:subject) do 
            xml.cdata! subject_string
          end
        end

        # if there is a license, put it under dc:rights
        xml.dc :rights, rss_dc_rights(item)

        # this is mime type
        format_string = rss_dc_format(item)
        xml.dc :format, format_string if format_string

        # this is currently only used for topic type
        rss_dc_coverage_array(item).each do |coverage_string|
          xml.dc :coverage, coverage_string
        end
      end
    end
  end
end
