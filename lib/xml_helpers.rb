module XmlHelpers
  unless included_modules.include? XmlHelpers
    def appropriate_protocol_for(item)
      protocol = "http"
      if FORCE_HTTPS_ON_RESTRICTED_PAGES &&
          ( ( item.respond_to?(:private) && item.private? ) ||
            ( item.respond_to?(:commentable_private?) && item.commentable_private? ) )

        protocol = "https"
      end
      protocol
    end

    def file_url_from_bits_for(item, host, protocol = nil)
      protocol = protocol || appropriate_protocol_for(item)
      the_url = String.new
      if item.class.name == 'StillImage'
        the_url = "#{protocol}://#{host}#{item.original_file.public_filename}"
      else
        the_url = "#{protocol}://#{host}#{item.public_filename}"
      end
      the_url
    end

    def xml_enclosure_for_item_with_file(xml, item, host, protocol = nil)
      if (item.respond_to?(:public_filename) && !item.public_filename.blank?) ||
          (item.respond_to?(:original_file) && !item.original_file.blank?)
        protocol = protocol || "http"
        args = { :type => item.content_type,
          :length => item.size.to_s,
          :url => file_url_from_bits_for(item, host, protocol) }

        if item.class.name == 'ImageFile'
          args[:width] = item.width
          args[:height] = item.height
        end
        xml.enclosure args
      end
    end
  end
end
