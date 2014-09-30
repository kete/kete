
# Note:
#
# * if an topics related items change it is considered updated, if another item is added to a topic
#   it's not considered updated.
# * If a model directly related to this item is updated (say the user or the saved image) the item 
#   is considered is changed.
# * We're not listing comments
# * udpated_since=date_string is handled by Ruby's DateTime.parse can handle (which include iso8601, rfc3339, rfc2822, rfc822)


xml.instruct! :xml, :version => "1.0" 
xml.rss("version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/") do
  xml.channel do
    xml.title("#{SystemSetting.site_domain} StillImages RSS Feed")
    xml.link "http://#{SystemSetting.site_url}}"
    xml.description "#{SystemSetting.pretty_site_name} StillImage ordered by most update-time"
    xml.language "en-nz"
    xml.ttl "60" 

    @items.each do |item|
      xml.item do
                # oai_dc_xml_oai_datestamp(xml)
                # oai_dc_xml_oai_set_specs(xml)
        xml.guid "rss:#{SystemSetting.site_domain}:#{item.basket.urlified_name}:#{item.class.name}:#{item.id}", isPermaLink: "false"
        xml.title item.title        
        xml.pubDate item.updated_at.utc.xmlschema
        xml.link basket_still_image_index_url(item.basket, item)


        xml.dc :identifier, rss_dc_identifier(item)
        xml.dc :title,      rss_dc_title(item)
        xml.dc :publisher,  rss_dc_publisher(item)

        # appropriate description(s) elements will be determined
        # since we call it without specifying
        description_text = rss_dc_description(item)
        if description_text
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
              inner_xml.tag!(escape_xml_name(k), v)
            end
          end
        end

        non_anonymous_fields.each do |array|
          dc_label, value =  array[0], array[1]
          xml.tag! dc_label, value if value.present?
        end


        # # related topics and items should have dc:subject elem here with their title
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