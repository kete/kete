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

    # if the item is a topic
    # put in an element for each related item
    # plus attributes for totals by zoom class
    # still_images should include image_file subelement for thumbnail
    # if item is not a topic
    # simply has related topics
    def xml_for_related_items(xml, item, passed_request = nil)
      # comments are the only zoom class without content_item_relations
      return if item.class == Comment

      protocol = appropriate_protocol_for(item)
      host = !passed_request.nil? ? passed_request[:host] : request.host

      totals_hash = Hash.new
      # only add to totals if there are items
      unless item.is_a?(Topic)
        total = item.topics.count
        totals_hash[:topics] = total if total > 0
      else
        ZOOM_CLASSES.each do |class_name|
          tableized = class_name.tableize
          total = 0
          unless class_name == 'Topic'
            total = item.send(tableized).count
          else
            total = item.parent_related_topics.count + item.child_related_topics.count
          end
          totals_hash[tableized.to_sym] = total if total > 0
        end
      end
      options = ['related_items']
      unless totals_hash.blank?
        options << totals_hash
        xml.related_items(totals_hash) do
          # get the thumbnails for any still images we have
          # in the future we may also have audio, video, too
          unless totals_hash[:still_images].blank?
            count = 1
            item.still_images.each do |image|
              xml.still_image(:title => image.title, :id => image.id, :relation_order => count ) do
                thumb = image.thumbnail_file
                xml.thumbnail(:height  => thumb.height, :width => thumb.width, :size => thumb.size, :src => protocol + '://' + host + thumb.public_filename)
              end
              count += 1
            end
          end
        end
      end
    end
  end
end
