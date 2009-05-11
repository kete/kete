require "oai_dc_helpers"
require "xml_helpers"
require "zoom_helpers"
require "zoom_controller_helpers"
require "extended_content_helpers"
require "kete_url_for"
module OaiZoom
  unless included_modules.include? OaiZoom
    def self.included(klass)
      klass.send :include, OaiDcHelpers
      klass.send :include, ZoomHelpers
      klass.send :include, ZoomControllerHelpers
      klass.send :include, ExtendedContentHelpers
      klass.send :include, ActionController::UrlWriter
      klass.send :include, KeteUrlFor
    end

    def simulated_request
      @simulated_request ||= { :host => SITE_URL,
        :protocol => appropriate_protocol_for(self),
        :request_uri => url_for_dc_identifier(self)}
    end

    def oai_record_xml(options = { })
      item = options[:item] || self
      request = @import_request || simulated_request
      record = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
        xml.send("OAI-PMH",
                 :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                 :"xsi:schemaLocation" => "http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd",
                 :"xmlns" => "http://www.openarchives.org/OAI/2.0/") do
          xml.responseDate(Time.now.utc.xmlschema)
          oai_dc_xml_request(xml, request)
          xml.GetRecord do
            xml.record do
              xml.header do
                oai_dc_xml_oai_identifier(xml)
                oai_dc_xml_oai_datestamp(xml)
                oai_dc_xml_oai_set_specs(xml)
              end
              xml.metadata do
                xml.send("oai_dc:dc",
                         :"xmlns:oai_dc" => "http://www.openarchives.org/OAI/2.0/oai_dc/",
                         :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                         :"xmlns:dc" => "http://purl.org/dc/elements/1.1/",
                         :"xmlns:dcterms" => "http://purl.org/dc/terms/",
                         :"xsi:schemaLocation" => "http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd") do
                  oai_dc_xml_dc_identifier(xml, request)
                  oai_dc_xml_dc_title(xml)
                  oai_dc_xml_dc_publisher(xml, request[:host])

                  # topic/document specific
                  oai_dc_xml_dc_description(xml, short_summary) if [Topic, Document].include?(self.class)

                  oai_dc_xml_dc_description(xml, description)

                  # gives use dc:description/files/version_of_item/enclosure
                  # for any associated binary files
                  # that can be used to derive the url for things like thumbnails
                  # or populate rss enclosure
                  # we are using non-oai_dc namespaces for keeping informationn about
                  # binary files (except for dc:source) with the search record
                  # DEPRECIATED
                  # oai_dc_xml_dc_description_for_file(xml,item,request)

                  # we do a dc:source element for the original binary file
                  oai_dc_xml_dc_source_for_file(xml, request)

                  oai_dc_xml_dc_creators_and_date(xml)

                  oai_dc_xml_dc_contributors_and_modified_dates(xml)

                  # all types at this point have an extended_content attribute
                  oai_dc_xml_dc_extended_content(xml)

                  # related topics and items should have dc:subject elem here with their title
                  oai_dc_xml_dc_relations_and_subjects(xml, request)

                  logger.info("after dc xml relations and subjects")

                  oai_dc_xml_dc_type(xml)

                  oai_dc_xml_tags_to_dc_subjects(xml)

                  # if there is a license, put it under dc:rights
                  oai_dc_xml_dc_rights(xml, request)

                  # this is mime type
                  oai_dc_xml_dc_format(xml)

                  # this is currently only used for topic type
                  oai_dc_xml_dc_coverage(xml)
                end
              end
              # this is meant to be a cache, outside of the oai_dc namespace
              # of things like thumbnails to related images for a topic
              # for non-topics
              # it should store related topics
              xml.kete do
                xml_for_related_items(xml, request)

                xml_for_thumbnail_image_file(xml, request)

                xml_for_media_content_file(xml, request)
              end
            end
          end
        end
      }
      record = record.to_xml
      logger.info("after record to_xml")
      record
    end

    def prepare_and_save_to_zoom(existing_connection = nil)
      reload # make sure we have the latest data
      private = @import ? @import.private : private?
      zoom_save(existing_connection)
    end


    # TODO: this may not be needed anymore
    def importer_oai_dc_xml_dc_identifier(xml,item, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end
      # HACK, brittle, but can't use url_for here
      xml.send("dc:identifier", fully_qualified_item_url({:host => host, :controller => zoom_class_controller(item.class.name), :item => item, :urlified_name => item.basket.urlified_name}))
    end

    # TODO: this may not be needed anymore
    def importer_oai_dc_xml_dc_relations_and_subjects(xml,item,passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end

      case item.class.name
      when 'Topic'
        ZOOM_CLASSES.each do |zoom_class|
          related_items = ''
          if zoom_class == 'Topic'
            related_items = item.related_topics
          else
            related_items = item.send(zoom_class.tableize)
          end
          related_items.each do |related|
            xml.send("dc:subject") {
              xml.cdata related.title
            } unless [BLANK_TITLE, NO_PUBLIC_VERSION_TITLE].include?(related.title)
            xml.send("dc:relation", importer_item_url({:host => host, :controller => zoom_class_controller(zoom_class), :item => related, :urlified_name => related.basket.urlified_name}, true))
          end
        end
      when 'Comment'
        # comments always point back to the thing they are commenting on
        commented_on_item = item.commentable
        xml.send("dc:subject") {
          xml.cdata commented_on_item.title
        } unless [BLANK_TITLE, NO_PUBLIC_VERSION_TITLE].include?(commented_on_item.title)
        xml.send("dc:relation", importer_item_url({:host => host, :controller => zoom_class_controller(commented_on_item.class.name), :item => commented_on_item, :urlified_name => commented_on_item.basket.urlified_name}, true))
      else
        item.topics.each do |related|
          xml.send("dc:subject") {
            xml.cdata related.title
          } unless [BLANK_TITLE, NO_PUBLIC_VERSION_TITLE].include?(related.title)
          xml.send("dc:relation", importer_item_url({:host => host, :controller => :topics, :item => related, :urlified_name => related.basket.urlified_name}, true))
        end
      end
    end

    # TODO: probably no longer needed
    def importer_oai_dc_xml_dc_rights(xml,item,passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end

      if item.respond_to?(:license) && !item.license.blank?
        rights = item.license.url
      else
        rights = importer_item_url({:host => host, :controller => 'topics', :item => item, :urlified_name => Basket.find(ABOUT_BASKET).urlified_name, :id => 4})
      end

      xml.send("dc:rights", rights)
    end

  end
end
