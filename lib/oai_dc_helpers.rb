include Utf8UrlFor
include ActionView::Helpers::SanitizeHelper
# oai dublin core xml helpers
# TODO: evaluate whether we can simply go with SITE_URL
# rather than request hacking
module OaiDcHelpers
  unless included_modules.include? OaiDcHelpers
    def self.included(klass)
      klass.send :include, XmlHelpers
    end

    # TODO: this is duplicated in application.rb, fix
    def user_to_dc_creator_or_contributor(user)
      user.user_name
    end

    def oai_dc_xml_request(xml,item, passed_request = nil)
      if !passed_request.nil?
        protocol = passed_request[:protocol]
        host = passed_request[:host]
        request_uri = passed_request[:request_uri]
      else
        protocol = request.protocol
        host= request.host
        request_uri = request.request_uri
      end
      basket_urlified_name = @current_basket.nil? ? item.basket.urlified_name : @current_basket.urlified_name
      xml.request(protocol + host + CGI::unescape(request_uri), :verb => "GetRecord", :identifier => "#{ZoomDb.zoom_id_stub}#{basket_urlified_name}:#{item.class.name}:#{item.id}", :metadataPrefix => "oai_dc")
    end

    def oai_dc_xml_oai_identifier(xml, item)
      xml.identifier("#{ZoomDb.zoom_id_stub}#{item.basket.urlified_name}:#{item.class.name}:#{item.id}")
    end

    # Walter McGinnis, 2008-10-05
    # adding better logic for determining last time the item was changed
    # we want the datestamp to reflect the most recent change to the item
    # that can be either when it is created/edited
    # or when a relationship has been added
    # note that if a relation is removed, this may result in rolling back in time
    # of datestamp, which may be counterintuitive, however that is a rare case
    def oai_dc_xml_oai_datestamp(xml, item)
      most_recent_updated_at = item.updated_at

      if item.class.name == 'Topic'
        # topics can be on either side of the content_item_relation join model
        # so to get all possible relations, you have to combine them
        all_relations = item.content_item_relations + item.child_content_item_relations

        if all_relations.size > 0
          all_relations.sort! { |a,b| a.updated_at <=> b.updated_at }

          last_relation = all_relations.last
          if last_relation.updated_at > most_recent_updated_at
            most_recent_updated_at = last_relation.updated_at
          end
        end
      elsif item.class.name != 'Comment' && item.content_item_relations.count > 0 &&
          item.content_item_relations.last.updated_at > most_recent_updated_at
        most_recent_updated_at = item.content_item_relations.last.updated_at
      end

      xml.datestamp(most_recent_updated_at.utc.xmlschema)
    end

    # Walter McGinnis, 2008-06-16
    # adding oai pmh set support
    # assumes public zoom_db
    def oai_dc_xml_oai_set_specs(xml, item)
      # get the sets that match the item
      set_specs = Array.new
      ZoomDb.find(1).active_sets.each do |base_set|
        set_specs += base_set.matching_specs(item)
      end

      set_specs.each do |set_spec_value|
        xml.setSpec(set_spec_value)
      end
    end

    def oai_dc_xml_dc_identifier(xml, item, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end

      uri_attrs = {
        :controller => zoom_class_controller(item.class.name),
        :action => 'show',
        :id => item,
        :format => nil,
        :urlified_name => item.basket.urlified_name
      }

      if item.class.name == 'Comment'
        # comments always point back to the thing they are commenting on
        commented_on_item = item.commentable
        uri_attrs = {
          :controller => zoom_class_controller(commented_on_item.class.name),
          :action => 'show',
          :id => commented_on_item,
          :urlified_name => commented_on_item.basket.urlified_name,
          :anchor => "comment-#{item.id}",
          :private => item.commentable_private?.to_s
        }
      else
        # Link to private version if generating OAI record for it..
        if item.respond_to?(:private) && item.private?
          # don't put title in url for private items
          uri_attrs.merge!({ :private => "true", :id => item.id.to_s })
        end
      end

      # If the item is private and SSL is configured, use https instead of http for full URL for the
      # record.
      protocol = appropriate_protocol_for(item)

      xml.tag!("dc:identifier", "#{protocol}://#{host}#{utf8_url_for(uri_attrs.merge(:only_path => true))}")
    end

    def oai_dc_xml_dc_title(xml, item)
      xml.tag!("dc:title", item.title)
    end

    def oai_dc_xml_dc_publisher(xml, publisher = nil)
      # this website is the publisher by default
      if publisher.nil?
        xml.tag!("dc:publisher", request.host)
      else
        xml.tag!("dc:publisher", publisher)
      end
    end

    def oai_dc_xml_dc_description(xml, description)
      unless description.blank?
        # strip out embedded html
        # it only adds clutter at this point and fails oai_dc validation, too
        # also pulling out some entities that sneak in
        description = strip_tags(description)

        # convert unicode characters from entities back to unicode chars
        require 'htmlentities'
        entities = HTMLEntities.new
        description = entities.decode(description)

        # escape xml special chars &, <, and >
        description = CGI::escapeHTML(description)

        xml.tag!("dc:description", description)
      end
    end

    def oai_dc_xml_dc_creators_and_date(xml, item)
      item_created = item.created_at.utc.xmlschema
      xml.tag!("dc:date", item_created)
      item.creators.each do |creator|
        user_name = user_to_dc_creator_or_contributor(creator)
        xml.tag!("dc:creator", user_name)
        # we also add user.login, which is unique per site
        # whereas user_name is not
        # this way we can limit exactly to one user
        xml.tag!("dc:creator", creator.login) unless user_name == creator.login
      end
    end

    # TODO: this attribute isn't coming over even though it's in the select
    # contribution_date = contributor.version_created_at.to_date
    # xml.tag!("dcterms:modified", contribution_date)
    def oai_dc_xml_dc_contributors_and_modified_dates(xml, item)
      item.contributors.each do |contributor|
        user_name = user_to_dc_creator_or_contributor(contributor)
        xml.tag!("dc:contributor", user_name)
        # we also add user.login, which is unique per site
        # whereas user_name is not
        # this way we can limit exactly to one user
        xml.tag!("dc:contributor", contributor.login) unless user_name == contributor.login
      end
    end

    def oai_dc_xml_dc_relations_and_subjects(xml, item, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end

      # in theory, direct comments might be added in as relations here
      # but since there url is the thing they are commenting on
      # then it's overkill
      # however, if we are in the comment record,
      # we want to add the commented on item as a relation
      case item.class.name
      when 'Topic'
        ZOOM_CLASSES.each do |zoom_class|
          related_items = String.new
          if zoom_class == 'Topic'
            related_items = item.related_topics
          else
            related_items = item.send(zoom_class.tableize)
          end
          related_items.each do |related|
            xml.tag!("dc:subject", related.title.gsub("& ", "&amp; "))
            xml.tag!("dc:relation", "http://#{host}#{utf8_url_for(:controller => zoom_class_controller(zoom_class), :action => 'show', :id => related, :format => nil, :urlified_name => related.basket.urlified_name)}")
          end
        end
      when 'Comment'
        # comments always point back to the thing they are commenting on
        commented_on_item = item.commentable
        xml.tag!("dc:subject", commented_on_item.title.gsub("& ", "&amp; "))
        xml.tag!("dc:relation", "http://#{host}#{utf8_url_for(:controller => zoom_class_controller(commented_on_item.class.name), :action => 'show', :id => commented_on_item, :format => nil, :urlified_name => commented_on_item.basket.urlified_name)}")
      else
        item.topics.each do |related|
          xml.tag!("dc:subject", related.title.gsub("& ", "&amp; "))
          xml.tag!("dc:relation", "http://#{host}#{utf8_url_for(:controller => 'topics', :action => 'show', :id => related, :format => nil, :urlified_name => related.basket.urlified_name)}")
        end
      end
    end

    def oai_dc_xml_tags_to_dc_subjects(xml, item)
      item.tags.each do |tag|
        xml.tag!("dc:subject", tag.name)
      end
    end

    def oai_dc_xml_dc_type(xml, item)
      # topic's type is the default
      type = "InteractiveResource"
      case item.class.name
      when "AudioRecording"
        type = 'Sound'
      when "StillImage"
        type = 'StillImage'
      when 'Video'
        type = 'MovingImage'
      end
      xml.tag!("dc:type", type)
    end

    def oai_dc_xml_dc_format(xml, item)
      # item's content type is the default
      format = String.new
      html_classes = ['Topic', 'Comment', 'WebLink']
      case item.class.name
      when *html_classes
        format = 'text/html'
      when 'StillImage'
        if !item.original_file.nil?
          format = item.original_file.content_type
        end
      else
        format = item.content_type
      end
      if !format.blank?
        xml.tag!("dc:format", format)
      end
    end

    # currently only relevant to topics
    def oai_dc_xml_dc_coverage(xml, item)
      return unless item.is_a?(Topic)
      topic_type = item.topic_type
      topic_type.ancestors.each do |ancestor|
        xml.tag!("dc:coverage", ancestor.name)
      end
      xml.tag!("dc:coverage", topic_type.name)
    end

    # if there is a license for item, put in its url
    # otherwise site's terms and conditions url
    def oai_dc_xml_dc_rights(xml, item)
      if item.respond_to?(:license) && !item.license.blank?
        rights = item.license.url
      else
        rights = SITE_URL.chop + utf8_url_for(
          :id => 4,
          :urlified_name => Basket.find(ABOUT_BASKET).urlified_name,
          :action => 'show',
          :controller => 'topics',
          :escape => false
        )
      end

      xml.tag!("dc:rights", rights)
    end

    def oai_dc_xml_dc_description_for_file(xml, item, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end

      if ::Import::VALID_ARCHIVE_CLASSES.include?(item.class.name)
        xml.tag!("dc:description") do
          xml.files do
            # images we describe all image versions via image_files
            # where as everything else only has one file
            if item.class.name == 'StillImage'
              item.image_files.each do |image_file|
                xml.tag!('file') do
                  xml_enclosure_for_item_with_file(xml, image_file, host)
                end
              end
            else
              xml.tag!(item.class.name.tableize.singularize) do
                xml_enclosure_for_item_with_file(xml, item, host)
              end
            end
          end
        end
      end
    end
    def oai_dc_xml_dc_source_for_file(xml, item, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end

      if ::Import::VALID_ARCHIVE_CLASSES.include?(item.class.name)
        xml.tag!("dc:source", file_url_from_bits_for(item, host))
      end
    end
  end
end
