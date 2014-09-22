
# Note:
#
# * if an topics related items change it is considered updated, if another item is added to a topic
#   it's not considered updated.
# * If a model directly related to this item is updated (say the user or the saved image) the item 
#   is considered is changed.
# * We're not listing comments


# !! Methods pulled from oai_dc_helper.rb and simplified to return strings/nil 

def rss_dc_identifier(item)
  # ROB: this seemed to adjust the url if the was latest item was private. We're just ignoring this.
  basket_still_image_url(item.basket, item)
end

def rss_dc_title(item)
  item.title
end

def rss_dc_publisher(item)
  SystemSetting.site_domain
end

def rss_dc_description(item)
  # ROB: embedded html is stripped out because this is what old oai sources do.

  # ROB: Topic and Document have a short summary option. The old version listed this as
  # the description giving two dc:description tags. We aren't doing this.

  if item.description.present?
    item.description.strip_tags
  else
    nil
  end
end

def rss_dc_source_for_file(item)
  if ::Import::VALID_ARCHIVE_CLASSES.include?(item.class.name)
    file_url_from_bits_for(item, request[:host])
  else
    nil
  end
end

def rss_dc_date(item)
  item.updated_at.utc.xmlschema
end

def rss_dc_creators_array(item)
  # user.login is unique per site whereas user_name is not.
  # This way we can limit exactly to one user.

  array = item.creators.map do |creator|
    sub_array = [ creator.user_name ]
    sub_array << creator.login if creator.user_name != creator.login
  end
  array.flatten
end

def rss_dc_contributors_array(item)
  # user.login is unique per site whereas user_name is not.
  # This way we can limit exactly to one user.

  array = item.contributors.select(:login).uniq.map do |contributor|
    sub_array = [ contributor.user_name ]
    sub_array << contributor.login if contributor.user_name != contributor.login
  end
  array.flatten
end

def rss_dc_relations_array(item)
  item.related_items.map do |related|
    # ROB: Previously a dc:subject tag was created using related.title. This 
    #      seems unnecessary and wasn't implemented.
    url_for_dc_identifier(related, { :force_http => true, :minimal => true }.merge(request.params) ) 
  end
end

def rss_dc_type(item) 
  if item.is_a? AudioRecording
    'Sound'
  elsif item.is_a? StillImage
    'StillImage'
  elsif item.is_a? Video
    'MovingImage'
  else # topic's type is the default
    "InteractiveResource"
  end
end

def rss_tags_to_dc_subjects_array(item)
  item.tags.map(&:name)
end

def rss_dc_rights(item)
  if item.respond_to?(:license) && !item.license.blank?
    item.license.url
  else
    terms_and_conditions_topic = Basket.about_basket.topics.find(:first, :conditions => "UPPER(title) like '%TERMS AND CONDITIONS'")
    terms_and_conditions_topic ||= 4

    basket_topic_url(terms_and_conditions_topic.basket, terms_and_conditions_topic)
  end
end

def rss_dc_format(item)
  if [ Topic, Comment, WebLink ].include?(item.class)
    'text/html'
  elsif item.is_a?(StillImage) && item.original_file.present?
    item.original_file.content_type
  elsif item.is_a?(StillImage) && item.original_file.blank?
    nil
  else
    item.content_type
  end
end

# currently only relevant to topics
def rss_dc_coverage_array(item)
  array = []

  if item.is_a?(Topic)
    item.topic_type.ancestors.each do |ancestor|
      array << item.ancestor.name
    end
    array << item.topic_type.name
  end

  array
end


def rss_dc_extended_content(xml, item)
  @builder_instance = xml

  # We start with something like: {"text_field_multiple"=>{"2"=>{"text_field"=>{"xml_element_name"=>"dc:description", "value"=>"Value"}}, "3"=>{"text_field"=>{"xml_element_name"=>"dc:description", "value"=>"Second value"}}}, "married"=>"No", "check_boxes_multiple"=>{"1"=>{"check_boxes"=>"Yes"}}, "vehicle_type"=>{"1"=>"Car", "2"=>"Coupé"}, "truck_type_multiple"=>{"1"=>{"truck_type"=>{"1"=>"Lorry"}}, "2"=>{"truck_type"=>{"1"=>"Tractor Unit", "2"=>"Tractor with one trailer"}}}}

  @anonymous_fields = []

  fields_with_position = item.xml_attributes

  fields_in_sorted_array = fields_with_position.keys.sort_by { |s| s.to_s }.map { |key| fields_with_position[key] }
  fields_in_sorted_array.each do |field_hash|
      field_hash.each_pair do |field_key, field_data|
      # If this is google map contents, and no_map is '1', then do not use this data
      next if field_data.is_a?(Hash) && field_data['no_map'] && field_data['no_map'] == '1'
      
      if field_key =~ /_multiple$/
        # We are dealing with multiple instances of an attribute
        field_data.each_pair do |index, data|
          rss_for_field_dataset(field_key, data.values.first)
        end
      else
        rss_for_field_dataset(field_key, field_data)
      end
    end
  end

  # Build the anonymous fields that have no dc:* attributes.
  @builder_instance.dc(:description) do |nested|
    @anonymous_fields.each do |k, v|
      nested.safe_send(k, v)
    end
  end
end

def rss_for_field_dataset(field_key, data)
  original_field_key = field_key.gsub(/_multiple/, '')

  if data.is_a?(String)
    # This works as expected
    # In the most simple case, the content is represented as "key" => "value", so use this directly
    # now if it's available.
    @anonymous_fields << [original_field_key, data]
  elsif data.has_key?("value")
    # We add a dc:date for 5 years before and after the value specified
    # We also convert the single YYYY value to a format Zebra can search against
    # Note: We use DateTime instead of just Date/Time so that we can get dates before 1900
    if data.has_key?("circa")
      data['value'] = Time.zone.parse("#{data['value']}-01-01").xmlschema
      if data['circa'] == '1'
        five_years_before, five_years_after = (data['value'].to_i - 5), (data['value'].to_i + 5)
        @builder_instance.send("dc:date", Time.zone.parse("#{five_years_before}-01-01").xmlschema)
        @builder_instance.send("dc:date", Time.zone.parse("#{five_years_after}-12-31").xmlschema)
      end
    end

    # When xml_element_name is an attribute, the value is stored in a value key in a Hash.
    if data["xml_element_name"].blank?
      @anonymous_fields << [original_field_key, data["value"]]
    else
      # safe_send will drop the namespace from the element and therefore our dc elements
      # will not be parsed by zebra, only use safe_send on non-dc elements
      if data["xml_element_name"].include?("dc:")
        @builder_instance.send(data["xml_element_name"], data["value"])
      else
        @builder_instance.safe_send(data["xml_element_name"], data["value"])
      end
    end
  else

    # Example of what we might have in data at this point
    # {"xml_element_name"=>"dc:subject",
    #  "1"=>{"value"=>"Recreation", "label"=>"Sports & Recreation"},
    #  "2"=>"Festivals",
    #  "3"=>"New Year"}

    # This means we're dealing with a second set of nested values, to build these now.
    data_for_values = data.reject { |k, v| k == 'xml_element_name' || k == 'label' }.map { |k, v| v }

    # By this stage, we may have either of the following:
    # [{:label => 'Something', :value => 'This'}, {:label => 'Another', :value => 'That'}]
    # ['This', 'That']
    # (or a combination of both). So in this case, lets collect the correct values before continuing
    data_for_values.collect! { |v| (v.is_a?(Hash) && v['value']) ? v['value'] : v }.flatten.compact

    return nil if data_for_values.empty?

    if data["xml_element_name"].blank?
      @anonymous_fields << [original_field_key, ":#{data_for_values.join(":")}:"]
    else
      if data["xml_element_name"].include?("dc:")
        # we want the namespace for dc xml_element_name
        @builder_instance.send(data["xml_element_name"], ":#{data_for_values.join(":")}:")
      else
        @builder_instance.safe_send(data["xml_element_name"], ":#{data_for_values.join(":")}:")
      end
    end
  end

end


xml.instruct! :xml, :version => "1.0" 
xml.rss("version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/") do
  xml.channel do
    xml.title("#{SystemSetting.site_domain} StillImages RSS Feed")
    xml.link "http://#{SystemSetting.site_url}}"
    xml.description "#{SystemSetting.pretty_site_name} StillImage ordered by most update-time"
    xml.language "en-nz"
    xml.ttl "60" 

    #[ StillImage.find(7), StillImage.find(11), StillImage.find(9) ].each do |item|
    [ StillImage.find(79) ].each do |item|
      xml.item do
                # oai_dc_xml_oai_datestamp(xml)
                # oai_dc_xml_oai_set_specs(xml)
        xml.guid "rss:#{SystemSetting.site_domain}:#{item.basket.urlified_name}:#{item.class.name}:#{item.id}", isPermaLink: "false"
        xml.title item.title        
        xml.pubDate item.updated_at.utc.xmlschema
        xml.link basket_still_image_index_url(item.basket, item)

        # ----------------------------
        xml.dc :MAHHHHHHHH, " ---------------- "
        xml.dc :MAHHHHHHHH, " ---------------- "
        # ----------------------------

        xml.dc :identifier, basket_still_image_url(item.basket, item)
        xml.dc :title, item.title
        xml.dc :publisher, SystemSetting.site_domain
        xml.dc(:description) {  xml.cdata!(item.description) }
        if item.class.name == 'StillImage'
          xml.dc :source, item.original_file.public_filename
        else
          xml.dc :source, item.public_filename
        end
        xml.dc :date, item.updated_at.utc.xmlschema
        
        if item.creator.present?
          xml.dc :creator, item.creator.display_name
          xml.dc :creator, item.creator.login
        end

    #       <dc:description/>
        xml.dc :type, "StillImage"
        item.tags.each do |tag|
          xml.dc(:subject) { xml.cdata! tag.name }
        end

        xml.dc :rights, item.license.url
        xml.dc :format, item.original_file.content_type

        # ----------------------------
        xml.dc :MAHHHHHHHH, " ---------------- "
        xml.dc :MAHHHHHHHH, " ---------------- "
        # ----------------------------

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

        xml.send("dc:subject") {
          xml.cdata! item.url
        } if item.is_a?(WebLink)

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
        rss_dc_extended_content(xml, item)

        # # related topics and items should have dc:subject elem here with their title
        rss_dc_relations_array(item).each do |relation_string|
          xml.dc :relation, relation_string
        end

        xml.dc :type, rss_dc_type(item)


        rss_tags_to_dc_subjects_array(item) do |subject_string|
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