# convenience methods for classes that have related items
module RelatedItems
  unless included_modules.include? RelatedItems
    # replaces oai_xml_helpers#related_items_of
    def related_items_hash
      # in the case we are adding relations or bulk importing, and multiple OAI records are
      # generated in the same controller request, we need to have a unique memoized instance
      # var for each item type and id. Having one single one (i.e. @related_items ||= ) won't
      # work because a collision occurs and results aren't regenerated, resulting in the child
      # item having the same memoized related items as the parent and the related items
      # functionality stops working correctly. Using instance_eval allows us to fix this issue
      # by generation a unique instance var that can be used by the same OAI generation later
      # but not by any other items OAI generation
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
