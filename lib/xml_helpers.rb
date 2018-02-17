module XmlHelpers
  unless included_modules.include? XmlHelpers

    def appropriate_protocol_for(item)
      protocol = 'http'
      if SystemSetting.force_https_on_restricted_pages &&
         ((item.respond_to?(:private) && item.private?) ||
           (item.respond_to?(:commentable_private?) && item.commentable_private?))

        protocol = 'https'
      end
      protocol
    end

    def file_url_from_bits_for(item, host, protocol = nil)
      protocol = protocol || appropriate_protocol_for(item)
      the_url = String.new
      the_url = if item.class.name == 'StillImage'
        "#{host}#{item.original_file.public_filename}"
      else
        "#{host}#{item.public_filename}"
                end
      the_url
    end

    def xml_enclosure_for_item_with_file(xml, item, host, protocol = nil)
      if (item.respond_to?(:public_filename) && !item.public_filename.blank?) ||
         (item.respond_to?(:original_file) && !item.original_file.blank?)
        protocol = protocol || 'http'
        args = {
          type: item.content_type,
          length: item.size.to_s,
          url: file_url_from_bits_for(item, host, protocol)
        }

        if item.class.name == 'ImageFile'
          args[:width] = item.width
          args[:height] = item.height
        end
        xml.enclosure args
      end
    end

    # output xml intended to give us all we need to know
    # to display the thumbnail for an item
    # in results (whether related to a topic, or as sole thumbnail for item)
    def xml_for_thumbnail_image_file(xml, item, passed_request = nil)
      # right now StillImage is the only class with thumbnails
      # this may change in the future for videos and documents
      # possibly even audio if there are samples
      # at that point, refactor accordingly
      # unless ATTACHABLE_CLASSES.include?(item.class.name)
      return unless item.is_a?(StillImage)
      # when being built for private search index, item's values are set to the latest private version's values
      # so already_at_blank_version? will return true
      # only if we are building for public search index
      # and there is only a placeholder public version
      # otherwise we are good to continue
      return unless !item.already_at_blank_version?

      protocol = appropriate_protocol_for(item)
      host = !passed_request.nil? ? passed_request[:host] : request.host

      thumb = item.thumbnail_file
      xml.thumbnail(height: thumb.height, width: thumb.width, size: thumb.size, src: protocol + '://' + host + thumb.public_filename)

      # http://cooliris.com/'s cooliris tool likes larger thumbnails for things to look good
      # include the medium version here, so that we may use it in Media RSS media:thumbnail tag
      # instead of the smaller thumbnail
      medium = item.medium_file
      xml.medium(height: medium.height, width: medium.width, size: medium.size, src: protocol + '://' + host + medium.public_filename)
    end

    # output xml intended to give us all we need to know
    # to display the content of any uploaded original
    # this will use large version for still images and original for everything else
    def xml_for_media_content_file(xml, item, passed_request = nil)
      # right now StillImage is the only class with thumbnails
      # this may change in the future for videos and documents
      # possibly even audio if there are samples
      # at that point, refactor accordingly
      # unless ATTACHABLE_CLASSES.include?(item.class.name)
      # don't add information about media content if the uploaded file should be private
      # unless we are building a private search index record
      return unless ATTACHABLE_CLASSES.include?(item.class.name)
      # when being built for private search index, item's values are set to the latest private version's values
      # so already_at_blank_version? will return true
      # only if we are building for public search index
      # and there is only a placeholder public version
      # otherwise we are good to continue
      return unless !item.already_at_blank_version?

      protocol = appropriate_protocol_for(item)
      host = !passed_request.nil? ? passed_request[:host] : request.host

      unless item.is_a?(StillImage)
        # original is not available for download to public viewers
        # so skip it, unless we are buildig a private search index record
        # which we can tell by seeing if the version is private
        # (in which case we are building the private search index)
        return if item.file_private? && !item.private?
        xml.media_content(
          size: item.size,
          content_type: item.content_type,
          src: protocol + '://' + host + item.public_filename
        )
      else
        # if there is any non-placeholder public version it is ok to return large version
        # for still images
        large = item.large_file
        xml.media_content(
          height: large.height, width: large.width,
          size: large.size,
          content_type: large.content_type,
          src: protocol + '://' + host + large.public_filename
        )
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
      return if item.is_a?(Comment)
      protocol = appropriate_protocol_for(item)
      host = !passed_request.nil? ? passed_request[:host] : request.host
      request = !passed_request.nil? ? passed_request : request

      totals_hash = Hash.new
      # only add to totals if there are items
      total = item.related_items.size
      if total > 0
        if item.is_a?(Topic)
          ZOOM_CLASSES.each do |class_name|
            class_total = item.related_items_hash[class_name].size
            totals_hash[class_name.tableize.to_sym] = class_total if class_total > 0
          end
        else
          totals_hash[:topics] = total if total > 0
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
            # parsing massive amounts of relations is cumbersome on the search side
            # and generating them also slows down the create/update actions for items
            # limiting here, since we are likely to only want this many
            # if the item is not private, don't allow private related still images
            options = {
              limit: SystemSetting.number_of_related_things_to_display_per_type,
              conditions: PUBLIC_CONDITIONS
            }

            options.delete(:conditions) if item.private

            item.still_images.find(:all, options).each do |image|
              xml.still_image(title: image.title, id: image.id, relation_order: count) do
                xml_for_thumbnail_image_file(xml, image, request)
              end
              count += 1
            end
          end
        end
      end
    end
  end
end
