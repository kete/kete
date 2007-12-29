module XmlHelpers
  unless included_modules.include? XmlHelpers
    def xml_enclosure_for_item_with_file(xml, item, host)
      args = { :type => item.content_type,
        :length => item.size.to_s,
        :url => "http://#{host}#{item.public_filename}" }

      if item.class.name == 'ImageFile'
        args[:width] = item.width
        args[:height] = item.height
      end
      xml.enclosure args
    end
  end
end
