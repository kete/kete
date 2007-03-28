# oai dublin core xml helpers
module OaiDcHelpers
  unless included_modules.include? OaiDcHelpers
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
      xml.request(protocol + host + request_uri, :verb => "GetRecord", :identifier => "#{ZoomDb.zoom_id_stub}#{@current_basket.urlified_name}:#{item.class.name}:#{item.id}", :metadataPrefix => "oai_dc")
    end

    def oai_dc_xml_oai_identifier(xml,item)
      xml.identifier("#{ZoomDb.zoom_id_stub}#{@current_basket.urlified_name}:#{item.class.name}:#{item.id}")
    end

    def oai_dc_xml_dc_identifier(xml,item, passed_request = nil)
      if !passed_request.nil?
        host = passed_request[:host]
      else
        host = request.host
      end
      xml.tag!("dc:identifier", "http://#{host}#{url_for(:controller => zoom_class_controller(item.class.name), :action => 'show', :id => item, :format => nil, :urlified_name => @current_basket.urlified_name)}")
    end

    def oai_dc_xml_dc_title(xml,item)
      xml.tag!("dc:title", item.title)
    end

    def oai_dc_xml_dc_publisher(xml,publisher = nil)
      # this website is the publisher by default
      if publisher.nil?
        xml.tag!("dc:publisher", request.host)
      else
        xml.tag!("dc:publisher", publisher)
      end
    end

    def oai_dc_xml_dc_description(xml,description)
      xml.tag!("dc:description", description)
    end

    def oai_dc_xml_dc_creators_and_date(xml,item)
      item_created = item.created_at.to_s(:db)
      xml.tag!("dc:date", item_created)
      item.creators.each do |creator|
        xml.tag!("dc:creator", user_to_dc_creator_or_contributor(creator))
      end
    end

    # TODO: this attribute isn't coming over even though it's in the select
    # contribution_date = contributor.version_created_at.to_date
    # xml.tag!("dcterms:modified", contribution_date)
    def oai_dc_xml_dc_contributors_and_modified_dates(xml,item)
      item.contributors.each do |contributor|
        xml.tag!("dc:contributor", user_to_dc_creator_or_contributor(contributor))
      end
    end

    def oai_dc_xml_dc_relations_and_subjects(xml,item,passed_request = nil)
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
            xml.tag!("dc:relation", "http://#{host}#{url_for(:controller => zoom_class_controller(zoom_class), :action => 'show', :id => related, :format => nil, :urlified_name => related.basket.urlified_name)}")
          end
        end
      else
        item.topics.each do |related|
          xml.tag!("dc:subject", related.title)
          xml.tag!("dc:relation", "http://#{host}#{url_for(:controller => :topics, :action => 'show', :id => related, :format => nil, :urlified_name => related.basket.urlified_name)}")
        end
      end
    end

    def oai_dc_xml_tags_to_dc_subjects(xml,item)
      item.tags.each do |tag|
        xml.tag!("dc:subject", tag.name)
      end
    end

    def oai_dc_xml_dc_type(xml,item)
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

    def oai_dc_xml_dc_format(xml,item)
      # item's content type is the default
      format = String.new
      case item.class.name
      when 'Topic'
        format = 'text/html'
      when 'WebLink'
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
  end
end
