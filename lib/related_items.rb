# convenience methods for classes that have related items
module RelatedItems
  unless included_modules.include? RelatedItems
    # replaces oai_xml_helpers#related_items_of
    def related_items_hash
      @related_items_hash ||= begin
        related_items_hash = Hash.new
        related_items_hash['Topic'] = self.is_a?(Topic) ? related_topics : topics

        if self.is_a?(Topic)
          ZOOM_CLASSES.each do |zoom_class|
            next if zoom_class == 'Topic'
            related_items_hash[zoom_class] = self.send(zoom_class.tableize)
          end
        end
        related_items_hash
      end
    end

    # build up one collection of all types of related items
    # this will also trigger @related_items_hash to be instanciated if it doesn't already exist
    def related_items
      related_items = Array.new
      related_items_hash.values.each { |v| related_items += v }
      related_items
    end
  end
end
