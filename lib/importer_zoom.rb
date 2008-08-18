require "oai_dc_helpers"
require "xml_helpers"
require "zoom_helpers"
require "zoom_controller_helpers"
module ImporterZoom
  unless included_modules.include? ImporterZoom
    def self.included(klass)
      klass.send :include, OaiDcHelpers
      klass.send :include, ZoomHelpers
      klass.send :include, ZoomControllerHelpers
      klass.send :include, ActionController::UrlWriter
    end

    def importer_oai_record_xml(options = { })
      item = options[:item]
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.tag!("OAI-PMH", "xmlns:xsi".to_sym => "http://www.w3.org/2001/XMLSchema-instance", "xsi:schemaLocation".to_sym => "http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd", "xmlns" => "http://www.openarchives.org/OAI/2.0/") do
        xml.responseDate(Time.now.utc.xmlschema)
        oai_dc_xml_request(xml,item,@import_request)
        xml.GetRecord do
          xml.record do
            xml.header do
              oai_dc_xml_oai_identifier(xml,item)
              xml.datestamp(Time.now.utc.xmlschema)
              oai_dc_xml_oai_set_specs(xml,item)
            end
            xml.metadata do
              xml.tag!("oai_dc:dc", "xmlns:oai_dc".to_sym => "http://www.openarchives.org/OAI/2.0/oai_dc/", "xmlns:xsi".to_sym => "http://www.w3.org/2001/XMLSchema-instance", "xmlns:dc".to_sym => "http://purl.org/dc/elements/1.1/", "xmlns:dcterms".to_sym => "http://purl.org/dc/terms/", "xsi:schemaLocation".to_sym => "http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd") do
                importer_oai_dc_xml_dc_identifier(xml,item,@import_request)
                oai_dc_xml_dc_title(xml,item)
                oai_dc_xml_dc_publisher(xml,@import_request[:host])

                if ['Topic', 'Document'].include?(item.class.name)
                  oai_dc_xml_dc_description(xml,item.short_summary)
                end

                oai_dc_xml_dc_description(xml,item.description)

                # gives use dc:description/files/version_of_item/enclosure
                # for any associated binary files
                # that can be used to derive the url for things like thumbnails
                # or populate rss enclosure
                oai_dc_xml_dc_description_for_file(xml,item,@import_request)

                # we do a dc:source element for the original binary file
                oai_dc_xml_dc_source_for_file(xml, item, @import_request)

                oai_dc_xml_dc_creators_and_date(xml,item)

                oai_dc_xml_dc_contributors_and_modified_dates(xml,item)

                # all types at this point have an extended_content attribute
                oai_dc_xml_dc_extended_content(xml,item)

                # related topics and items should have dc:subject elem here with their title
                importer_oai_dc_xml_dc_relations_and_subjects(xml, item, @import_request)

                logger.info("after dc xml relations and subjects")

                oai_dc_xml_dc_type(xml,item)

                oai_dc_xml_tags_to_dc_subjects(xml,item)

                # if there is a license, put it under dc:rights
                oai_dc_xml_dc_rights(xml, item)

                # this is mime type
                oai_dc_xml_dc_format(xml,item)
              end
            end
          end
        end
      end
      record = xml.to_s
      logger.info("after record to_s")
      return record.gsub("<to_s\/>","")
    end

    def importer_prepare_zoom(item)
      # only do this for members of ZOOM_CLASSES
      if ZOOM_CLASSES.include?(item.class.name)
        begin
          item.oai_record = importer_oai_record_xml(:item => item)
          item.basket_urlified_name = item.basket.urlified_name
        rescue
          logger.error("prepare_and_save_to_zoom error: #{$!.to_s}")
        end
      end
    end

    def importer_prepare_and_save_to_zoom(item)
      importer_prepare_zoom(item)
      item.private = @import.private
      item.zoom_save
    end

    def importer_item_url(options = {})
      host = options[:host]
      item = options[:item]
      controller = options[:controller]
      urlified_name = options[:urlified_name]
      protocol = options[:protocol] || appropriate_protocol_for(item)
      "#{protocol}://#{host}/#{urlified_name}/#{controller}/show/#{item.to_param}"
    end

    def importer_oai_dc_xml_dc_identifier(xml,item, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end
      # HACK, brittle, but can't use url_for here
      xml.tag!("dc:identifier", importer_item_url(:host => host, :controller => zoom_class_controller(item.class.name), :item => item, :urlified_name => item.basket.urlified_name))
    end

    def importer_oai_dc_xml_dc_relations_and_subjects(xml,item,passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end

      if item.class.name == 'Topic'
        ZOOM_CLASSES.each do |zoom_class|
          related_items = ''
          if zoom_class == 'Topic'
            related_items = item.related_topics
          else
            related_items = item.send(zoom_class.tableize)
          end
          related_items.each do |related|
            xml.tag!("dc:subject", related.title)
            xml.tag!("dc:relation", importer_item_url(:host => host, :controller => zoom_class_controller(zoom_class), :item => related, :urlified_name => related.basket.urlified_name))
          end
        end
      else
        item.topics.each do |related|
          xml.tag!("dc:subject", related.title)
          xml.tag!("dc:relation", importer_item_url(:host => host, :controller => :topics, :item => related, :urlified_name => related.basket.urlified_name))
        end
      end
    end
  end
end
