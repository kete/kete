module OaiXmlHelpers
  unless included_modules.include? OaiXmlHelpers

    def related_items_of(item, count_only=false)
      @related_items ||= begin
        related_items = Hash.new
        case item.class.name
        when 'Topic'
          ZOOM_CLASSES.each do |zoom_class|
            if zoom_class == 'Topic'
              related_items['Topic'] = Array.new
              if count_only
                count = item.parent_related_topics.count + item.child_related_topics.count
                count.times do |i|
                  related_items['Topic'] << nil
                end
              else
                related_items['Topic'] = item.related_topics
              end
            else
              related_items[zoom_class] = Array.new
              if count_only
                item.send(zoom_class.tableize).count.times do |i|
                  related_items[zoom_class] << nil
                end
              else
                related_items[zoom_class] = item.send(zoom_class.tableize)
              end
            end
          end
        else
          related_items['Topic'] = Array.new
          if count_only
            item.topics.count.times do |i|
              related_items['Topic'] << nil
            end
          else
            related_items['Topic'] = item.topics
          end
        end
        related_items
      end
    end

  end
end