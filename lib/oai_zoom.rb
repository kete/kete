require 'oai_dc_helpers'
require 'xml_helpers'
require 'zoom_helpers'
require 'zoom_controller_helpers'
require 'extended_content_helpers'
require 'kete_url_for'
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
      @simulated_request ||= { host: SITE_NAME,
        protocol: appropriate_protocol_for(self),
        request_uri: url_for_dc_identifier(self)}
    end

    def oai_record_xml(options = { })
      item = options[:item] || self
      request = @import_request || simulated_request
      record = Nokogiri::XML::Builder.new(encoding: 'UTF-8') { |xml|
        xml.send('OAI-PMH',
                 'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                 'xsi:schemaLocation' => 'http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd',
                 'xmlns' => 'http://www.openarchives.org/OAI/2.0/') do
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
                xml.send('oai_dc:dc',
                         'xmlns:oai_dc' => 'http://www.openarchives.org/OAI/2.0/oai_dc/',
                         'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                         'xmlns:dcterms' => 'http://purl.org/dc/terms/') do
                  oai_dc_xml_dc_identifier(xml, request)
                  oai_dc_xml_dc_title(xml)
                  oai_dc_xml_dc_publisher(xml, request[:host])

                  # appropriate description(s) elements will be determined
                  # since we call it without specifying
                  oai_dc_xml_dc_description(xml)

                  xml.send('dc:subject') {
                    xml.cdata item.url
                  } if item.is_a?(WebLink)

                  # we do a dc:source element for the original binary file
                  oai_dc_xml_dc_source_for_file(xml, request)

                  oai_dc_xml_dc_creators_and_date(xml)
                  oai_dc_xml_dc_contributors_and_modified_dates(xml)

                  # all types at this point have an extended_content attribute
                  oai_dc_xml_dc_extended_content(xml)

                  # related topics and items should have dc:subject elem here with their title
                  oai_dc_xml_dc_relations_and_subjects(xml, request)


                  oai_dc_xml_dc_type(xml)

                  oai_dc_xml_tags_to_dc_subjects(xml)

                  # if there is a license, put it under dc:rights
                  oai_dc_xml_dc_rights(xml)

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
                xml_for_related_items(xml, self, request)

                xml_for_thumbnail_image_file(xml, self, request)

                xml_for_media_content_file(xml, self, request)
              end
            end
          end
        end
      }
      record = record.to_xml
      logger.info('after record to_xml')
      record
    end

    def prepare_and_save_to_zoom(options = { })
      public_existing_connection = options[:public_existing_connection]
      private_existing_connection = options[:private_existing_connection]

      import_private = options[:import_private]
      @import_request = options[:import_request]
      skip_private = options[:skip_private]
      write_files = options[:write_files]

      was_private = private? # store whether the item was private or not before the reload

      reload # get the the most up to date version of self

      # This is always the public version..
      unless already_at_blank_version? || at_placeholder_public_version?
        unless is_a?(Comment) && commentable_private
          if write_files
            # write oai_record to appropriate directory for later indexing by zebraidx
            write_oai_record_file('public')
          else
            zoom_save(public_existing_connection)
          end
        end
      end

      # Redo the save for the private version
      if !skip_private &&
          (respond_to?(:private) && has_private_version? && !private?) ||
          (is_a?(Comment) && commentable_private)

        # have to reset self.oai_record, so that private version gets loaded in
        @oai_record = nil
        private_version do
          unless already_at_blank_version?
            if write_files
              # write oai_record to appropriate directory for later indexing by zebraidx
              write_oai_record_file('private')
            else
              zoom_save(private_existing_connection)
            end
          end
        end

        raise 'Could not return to public version' if private? && !is_a?(Comment)

      end

      private_version! if was_private # restore the privacy before we reloaded
    end

    # TODO: this may not be needed anymore
    def importer_oai_dc_xml_dc_identifier(xml,item, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end
      # HACK, brittle, but can't use url_for here
      xml.send('dc:identifier', fully_qualified_item_url({host: host, controller: zoom_class_controller(item.class.name), item: item, urlified_name: item.basket.urlified_name, locale: false}))
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
            xml.send('dc:subject') {
              xml.cdata related.title
            } unless [SystemSetting.blank_title, SystemSetting.no_public_version_title].include?(related.title)
            xml.send('dc:relation', importer_item_url({host: host, controller: zoom_class_controller(zoom_class), item: related, urlified_name: related.basket.urlified_name, locale: false}, true))
          end
        end
      when 'Comment'
        # comments always point back to the thing they are commenting on
        commented_on_item = item.commentable
        xml.send('dc:subject') {
          xml.cdata commented_on_item.title
        } unless [SystemSetting.blank_title, SystemSetting.no_public_version_title].include?(commented_on_item.title)
        xml.send('dc:relation', importer_item_url({host: host, controller: zoom_class_controller(commented_on_item.class.name), item: commented_on_item, urlified_name: commented_on_item.basket.urlified_name, locale: false}, true))
      else
        item.topics.each do |related|
          xml.send('dc:subject') {
            xml.cdata related.title
          } unless [SystemSetting.blank_title, SystemSetting.no_public_version_title].include?(related.title)
          xml.send('dc:relation', importer_item_url({host: host, controller: :topics, item: related, urlified_name: related.basket.urlified_name, locale: false}, true))
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
        rights = importer_item_url({host: host, controller: 'topics', item: item, urlified_name: Basket.find(SystemSetting.about_basket).urlified_name, id: 4, locale: false})
      end

      xml.send('dc:rights', rights)
    end

    def write_oai_record_file(root_dir)
      directory_path = oai_record_file_dirs(root_dir)
      FileUtils.mkdir_p directory_path unless File.directory?(directory_path)
      File.open(oai_record_file_path(root_dir), 'w') { |f| f.syswrite(oai_record) }
    end

    def oai_record_file_dirs(root_dir)
      "#{Rails.root}/zebradb/#{root_dir}/data/#{self.class.name.tableize}/" +
        ('%012d' % id).scan(/..../).join('/')
    end

    def oai_record_file_path(root_dir)
      oai_record_file_dirs(root_dir) + '/record.xml'
    end
  end
end
