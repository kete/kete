require "oai_dc_helpers"
require "xml_helpers"
require "zoom_helpers"
require "zoom_controller_helpers"
require "extended_content_helpers"
module ImporterZoom
  unless included_modules.include? ImporterZoom
    def self.included(klass)
      klass.send :include, OaiDcHelpers
      klass.send :include, ZoomHelpers
      klass.send :include, ZoomControllerHelpers
      klass.send :include, ExtendedContentHelpers
      klass.send :include, ActionController::UrlWriter
    end

    def importer_oai_record_xml(options = { })
      item = options[:item]
      record = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') { |xml|
        xml.send("OAI-PMH",
                 :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                 :"xsi:schemaLocation" => "http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd",
                 :"xmlns" => "http://www.openarchives.org/OAI/2.0/") do
          xml.responseDate(Time.now.utc.xmlschema)
          oai_dc_xml_request(xml, item, @import_request)
          xml.GetRecord do
            xml.record do
              xml.header do
                oai_dc_xml_oai_identifier(xml, item)
                oai_dc_xml_oai_datestamp(xml, item)
                oai_dc_xml_oai_set_specs(xml, item)
              end
              xml.metadata do
                xml.send("oai_dc:dc",
                         :"xmlns:oai_dc" => "http://www.openarchives.org/OAI/2.0/oai_dc/",
                         :"xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
                         :"xmlns:dc" => "http://purl.org/dc/elements/1.1/",
                         :"xmlns:dcterms" => "http://purl.org/dc/terms/",
                         :"xsi:schemaLocation" => "http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd") do
                  importer_oai_dc_xml_dc_identifier(xml, item, @import_request)
                  oai_dc_xml_dc_title(xml, item)
                  oai_dc_xml_dc_publisher(xml, @import_request[:host])

                  # topic/document specific
                  oai_dc_xml_dc_description(xml, item.short_summary) if ['Topic', 'Document'].include?(item.class.name)

                  oai_dc_xml_dc_description(xml,item.description)

                  xml.send("dc:subject") {
                    xml.cdata item.url
                  } if item.class.name == 'WebLink'

                  # gives use dc:description/files/version_of_item/enclosure
                  # for any associated binary files
                  # that can be used to derive the url for things like thumbnails
                  # or populate rss enclosure
                  # we are using non-oai_dc namespaces for keeping informationn about
                  # binary files (except for dc:source) with the search record
                  # DEPRECIATED
                  # oai_dc_xml_dc_description_for_file(xml,item,@import_request)

                  # we do a dc:source element for the original binary file
                  oai_dc_xml_dc_source_for_file(xml, item, @import_request)

                  oai_dc_xml_dc_creators_and_date(xml, item)

                  oai_dc_xml_dc_contributors_and_modified_dates(xml, item)

                  # all types at this point have an extended_content attribute
                  oai_dc_xml_dc_extended_content(xml, item)

                  # related topics and items should have dc:subject elem here with their title
                  importer_oai_dc_xml_dc_relations_and_subjects(xml, item, @import_request)

                  logger.info("after dc xml relations and subjects")

                  oai_dc_xml_dc_type(xml, item)

                  oai_dc_xml_tags_to_dc_subjects(xml, item)

                  # if there is a license, put it under dc:rights
                  importer_oai_dc_xml_dc_rights(xml, item, @import_request)

                  # this is mime type
                  oai_dc_xml_dc_format(xml, item)

                  # this is currently only used for topic type
                  oai_dc_xml_dc_coverage(xml, item)
                end
              end
              # this is meant to be a cache, outside of the oai_dc namespace
              # of things like thumbnails to related images for a topic
              # for non-topics
              # it should store related topics
              xml.kete do
                xml_for_related_items(xml, item, @import_request)

                xml_for_thumbnail_image_file(xml, item, @import_request)

                xml_for_media_content_file(xml, item, @import_request)
              end
            end
          end
        end
      }
      record = record.to_xml
      logger.info("after record to_xml")
      record
    end

    def importer_prepare_zoom(item)
      # only do this for members of ZOOM_CLASSES
      if ZOOM_CLASSES.include?(item.class.name)
        begin
          item.oai_record = importer_oai_record_xml(:item => item)
        rescue
          logger.error("prepare_and_save_to_zoom error: #{$!.to_s}")
        end
      end
    end

    def importer_prepare_and_save_to_zoom(item)
      item.reload # make sure we have the latest data
      importer_prepare_zoom(item)
      item.private = @import.private
      item.zoom_save
    end

    def importer_item_url(options = {}, is_relation=false)
      host = options[:host]
      item = options[:item]
      controller = options[:controller]
      urlified_name = options[:urlified_name]
      protocol = options[:protocol] || appropriate_protocol_for(item)

      url = "#{protocol}://#{host}/#{urlified_name}/"
      if item.class.name == 'Comment'
        commented_on_item = item.commentable
        url += zoom_class_controller(commented_on_item.class.name) + '/show/'
        if item.should_save_to_private_zoom?
          url += "#{commented_on_item.id.to_s}?private=true"
        else
          url += "#{commented_on_item.to_param}"
        end
        url += "#comment-#{item.id}"
      elsif is_relation
        # dc:relation fields should not have titles, or ?private=true in them
        url += "#{controller}/show/#{item.id}"
      elsif options[:id]
        url += "#{controller}/show/#{options[:id]}"
      else
        if item.respond_to?(:private) && item.private?
          url += "#{controller}/show/#{item.id.to_s}?private=true"
        else
          url += "#{controller}/show/#{item.to_param}"
        end
      end
      url
    end

    def importer_oai_dc_xml_dc_identifier(xml,item, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end
      # HACK, brittle, but can't use url_for here
      xml.send("dc:identifier", importer_item_url({:host => host, :controller => zoom_class_controller(item.class.name), :item => item, :urlified_name => item.basket.urlified_name}))
    end

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
