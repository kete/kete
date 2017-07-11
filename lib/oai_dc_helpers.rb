include Utf8UrlFor
include KeteUrlFor
include ActionView::Helpers::SanitizeHelper

# oai dublin core xml helpers
# TODO: evaluate whether we can simply go with SystemSetting.full_site_url
# rather than request hacking
module OaiDcHelpers
  unless included_modules.include? OaiDcHelpers
    def self.included(klass)
      klass.send :include, XmlHelpers
    end

    def oai_dc_xml_request(xml, passed_request = nil)
      if !passed_request.nil?
        request_uri = passed_request[:original_url]
      else
        request_uri = simulated_request[:original_url]
      end

      xml.request(request_uri, verb: "GetRecord", identifier: "#{ZoomDb.zoom_id_stub}#{basket_urlified_name}:#{self.class.name}:#{self.id}", metadataPrefix: "oai_dc")
    end

    def oai_dc_xml_oai_identifier(xml)
      xml.identifier("#{ZoomDb.zoom_id_stub}#{basket_urlified_name}:#{self.class.name}:#{self.id}")
    end

    # Walter McGinnis, 2008-10-05
    # adding better logic for determining last time the item was changed
    # we want the datestamp to reflect the most recent change to the item
    # that can be either when it is created/edited
    # or when a relationship has been added
    # note that if a relation is removed, this may result in rolling back in time
    # of datestamp, which may be counterintuitive, however that is a rare case
    def oai_dc_xml_oai_datestamp(xml)
      most_recent_updated_at = updated_at

      if self.is_a?(Topic)
        # topics can be on either side of the content_item_relation join model
        # so to get all possible relations, you have to combine them
        all_relations = Array.new

        # we only need the last from normal content relations and child content relations
        # to compare, not all of each
        if content_item_relations.count > 0
          all_relations << content_item_relations.last
        end

        if child_content_item_relations.count > 0
          all_relations << child_content_item_relations.last
        end

        if all_relations.size > 0
          all_relations.sort! { |a,b| a.updated_at <=> b.updated_at }

          last_relation = all_relations.last
          if last_relation.updated_at > most_recent_updated_at
            most_recent_updated_at = last_relation.updated_at
          end
        end
      elsif !self.is_a?(Comment) && content_item_relations.count > 0 &&
          content_item_relations.last.updated_at > most_recent_updated_at
        most_recent_updated_at = content_item_relations.last.updated_at
      end

      xml.datestamp(most_recent_updated_at.utc.xmlschema)
    end

    # Walter McGinnis, 2008-06-16
    # adding oai pmh set support
    # assumes public zoom_db
    def oai_dc_xml_oai_set_specs(xml)
      # get the sets that match the item
      set_specs = Array.new
      ZoomDb.find(1).active_sets.each do |base_set|
        set_specs += base_set.matching_specs(self)
      end

      set_specs.each do |set_spec_value|
        xml.setSpec(set_spec_value)
      end
    end

    def oai_dc_xml_dc_identifier(xml, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = simulated_request[:host]
      end

      uri_attrs = {
        controller: zoom_class_controller(self.class.name),
        action: 'show',
        id: self,
        format: nil,
        urlified_name: basket_urlified_name
      }

      if self.class.name == 'Comment'
        # comments always point back to the thing they are commenting on
        commented_on_item = self.commentable
        uri_attrs = {
          controller: zoom_class_controller(commented_on_item.class.name),
          action: 'show',
          id: commented_on_item,
          urlified_name: commented_on_item.basket.urlified_name,
          anchor: "comment-#{self.id}",
          private: self.commentable_private?.to_s
        }
      else
        # Link to private version if generating OAI record for it..
        if respond_to?(:private) && private?
          # don't put title in url for private items
          uri_attrs.merge!({ private: "true", id: self.id.to_s })
        end
      end

      # If the item is private and SSL is configured, use https instead of http for full URL for the
      # record.
      protocol = appropriate_protocol_for(self)

      xml.send("dc:identifier", utf8_url_for(uri_attrs.merge(protocol: protocol,
                                                             host: host,
                                                             locale: false)))
    end

    def oai_dc_xml_dc_title(xml, options = {})
      xml.send("dc:title", title, options)
    end

    def oai_dc_xml_dc_publisher(xml, publisher = nil)
      # this website is the publisher by default
      if publisher.nil?
        xml.send("dc:publisher", simulated_request[:host])
      else
        xml.send("dc:publisher", publisher)
      end
    end

    def oai_dc_xml_dc_description(xml, passed_description = nil, options = {})
      unless passed_description.blank?
        # strip out embedded html
        # it only adds clutter at this point and fails oai_dc validation, too
        # also pulling out some entities that sneak in
        xml.send("dc:description", options) {
          xml.cdata passed_description.strip_tags
        }
      else
        # if description is blank, we should do all descriptions for this zoom_class

        # topic/document specific
        # order is important, first description will be used as blurb
        # in result list
        if [Topic, Document].include?(self.class) && short_summary.present?
          oai_dc_xml_dc_description(xml, short_summary, options)
        end

        oai_dc_xml_dc_description(xml, description, options) if description.present?
      end
    end

    def oai_dc_xml_dc_creators_and_date(xml)
      # some sites, such as those that have lots of imported archival material,
      # will find that the date created is not useful in their search record
      # and will want to handle date data explicitly in their extended fields
      # only turn it on if specified in the system setting
      if SystemSetting.add_date_created_to_item_search_record?
        item_created = created_at.utc.xmlschema
        xml.send("dc:date", item_created)
      end
      creators.each do |creator|
        user_name = creator.user_name
        xml.send("dc:creator", user_name)
        # we also add user.login, which is unique per site
        # whereas user_name is not
        # this way we can limit exactly to one user
        xml.send("dc:creator", creator.login) unless user_name == creator.login
      end
    end

    # TODO: this attribute isn't coming over even though it's in the select
    # contribution_date = contributor.version_created_at.to_date
    # xml.send("dcterms:modified", contribution_date)
    def oai_dc_xml_dc_contributors_and_modified_dates(xml)
      contributors.all(select: "distinct(users.login), users.resolved_name").each do |contributor|
        user_name = contributor.user_name
        xml.send("dc:contributor", user_name)
        # we also add user.login, which is unique per site
        # whereas user_name is not
        # this way we can limit exactly to one user
        xml.send("dc:contributor", contributor.login) unless user_name == contributor.login
      end
    end

    def oai_dc_xml_dc_relations_and_subjects(xml, passed_request = {})
      # in theory, direct comments might be added in as relations here
      # but since there url is the thing they are commenting on
      # then it's overkill
      # however, if we are in the comment record,
      # we want to add the commented on item as a relation
      case self.class.name
      when 'Comment'
        # comments always point back to the thing they are commenting on
        commented_on_item = self.commentable
        xml.send("dc:subject") {
          xml.cdata commented_on_item.title
        } unless [SystemSetting.blank_title, SystemSetting.no_public_version_title].include?(commented_on_item.title)
        xml.send("dc:relation", url_for_dc_identifier(commented_on_item, { force_http: true, minimal: true }.merge(passed_request)))
      else
        related_count = related_items.count
        related_items.each do |related|
          # we skip subject if there are a large amount of related items
          # as zebra has a maximum record size
          if related_count < 500
            xml.send("dc:subject") {
              xml.cdata related.title
            } unless [SystemSetting.blank_title, SystemSetting.no_public_version_title].include?(related.title)
          end
          xml.send("dc:relation", url_for_dc_identifier(related, { force_http: true, minimal: true }.merge(passed_request)))
        end
      end
    end

    def oai_dc_xml_tags_to_dc_subjects(xml)
      tags.each do |tag|
        xml.send("dc:subject") {
          xml.cdata tag.name
        }
      end
    end

    def oai_dc_xml_dc_type(xml)
      # topic's type is the default
      type = "InteractiveResource"
      case self.class
      when AudioRecording
        type = 'Sound'
      when StillImage
        type = 'StillImage'
      when Video
        type = 'MovingImage'
      end
      xml.send("dc:type", type)
    end

    def oai_dc_xml_dc_format(xml)
      # item's content type is the default
      format = String.new
      html_classes = %w(Topic Comment WebLink)
      case self.class.name
      when *html_classes
        format = 'text/html'
      when 'StillImage'
        if !original_file.nil?
          format = original_file.content_type
        end
      else
        format = content_type
      end
      if !format.blank?
        xml.send("dc:format", format)
      end
    end

    # currently only relevant to topics
    def oai_dc_xml_dc_coverage(xml)
      return unless self.is_a?(Topic)
      topic_type.ancestors.each do |ancestor|
        xml.send("dc:coverage", ancestor.name)
      end
      xml.send("dc:coverage", topic_type.name)
    end

    # if there is a license for item, put in its url
    # otherwise site's terms and conditions url
    def oai_dc_xml_dc_rights(xml)
      terms_and_conditions_topic = Basket.about_basket.topics.find(:first,
                                                                   conditions: "UPPER(title) like '%TERMS AND CONDITIONS'")
      terms_and_conditions_topic ||= 4

      if respond_to?(:license) && !license.blank?
        rights = license.url
      else
        rights = utf8_url_for(
          host: SITE_NAME,
          id: terms_and_conditions_topic,
          urlified_name: Basket.about_basket.urlified_name,
          action: 'show',
          controller: 'topics',
          escape: false,
          locale: false
        )
      end

      xml.send("dc:rights", rights)
    end

    def oai_dc_xml_dc_source_for_file(xml, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = simulated_request[:host]
      end

      if ::Import::VALID_ARCHIVE_CLASSES.include?(self.class.name)
        xml.send("dc:source", file_url_from_bits_for(self, host))
      end
    end
  end
end
