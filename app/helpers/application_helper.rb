# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def zoom_class_humanize(zoom_class)
    humanized = String.new
    case zoom_class
      when "AudioRecording"
      humanized = 'Audio'
      when "WebLink"
      humanized = 'Web Link'
      when "StillImage"
      humanized = 'Image'
      else
      humanized = zoom_class.humanize
    end
    return humanized
  end

  def zoom_class_plural_humanize(zoom_class)
    plural_humanized = String.new
    case zoom_class
      when "AudioRecording"
      plural_humanized = 'Audio'
      when "WebLink"
      plural_humanized = 'Web Links'
      when "StillImage"
      plural_humanized = 'Images'
      else
      plural_humanized = zoom_class.humanize.pluralize
    end
    return plural_humanized
  end

  def zoom_class_controller(zoom_class)
    zoom_class_controller = String.new
    case zoom_class
      when "StillImage"
      zoom_class_controller = 'images'
      when "Video"
      zoom_class_controller = 'video'
      when "AudioRecording"
      zoom_class_controller = 'audio'
      else
      zoom_class_controller = zoom_class.tableize
    end
    return zoom_class_controller
  end

  # TODO: may want to replace this with better history plugin
  def link_to_last_stored_location
    if session[:return_to_title].blank?
      return link_to("&lt;&lt; Back to Kete Home", '/')
    else
      return link_to("&lt;&lt; Back to \"#{session[:return_to_title]}\"", session[:return_to])
    end
  end

  def link_to_item(item)
    link_to h(item.title), :controller => zoom_class_controller(item.class.name), :action => :show, :id => item.id
  end

  def link_to_related_to_source(options={})
    link_to(options[:phrase], { :controller => 'search', :source_item => options[:source_item], :current_class => options[:related_class], :urlified_name => 'site' }, { :class => 'small'})
  end

  def link_to_add_item(options={})
    phrase = options[:phrase]
    item_class = options[:item_class]
    return link_to("#{phrase} #{zoom_class_humanize(item_class)}", :controller => zoom_class_controller(item_class), :action => :new)
  end

  def link_to_add_related_item(options={})
    phrase = options[:phrase]
    item_class = options[:item_class]
    return link_to("#{phrase} #{zoom_class_humanize(item_class).downcase}", :controller => zoom_class_controller(item_class), :action => :new, :relate_to_topic_id => options[:relate_to_topic_id])

  end

  def item_related_topics_wrapper(options={})
    beginning_html = %q(
                    <div id="detail-linked">)
    if options[:topics].nil?
      beginning_html += "
                        <h3>This #{options[:class_phrase]} is not related to any topics at this time.</h3>"
    else
      beginning_html += "
                        <h3>This #{options[:class_phrase]} is related to the following topics:</h3>"
    end
    beginning_html +=%q(
                        <div id="detail-linked-toprow">)

    middle_html = String.new
    if !options[:topics].nil?
      middle_html = related_items_links(:source_item => options[:source_item], :items => options[:topics], :related_class => 'Topic')
    end

    end_html = %q(
                        </div>
                        <div class="cleaner">&nbsp;</div>
                </div>)
    return beginning_html + middle_html + end_html
  end

  def related_items_links(options={})
    source_item = options[:source_item]
    related_class = options[:related_class]

    items = options[:items]
    # cover the case where items is nil
    if items.nil?
      items = Array.new
    end

    relate_to_topic_id = options[:relate_to_topic_id]

    last_item_n = 0
    if related_class == 'StillImage'
      last_item_n = NUMBER_OF_RELATED_IMAGES_TO_DISPLAY
    else
      last_item_n = NUMBER_OF_RELATED_THINGS_TO_DISPLAY_PER_TYPE
    end

    end_range = last_item_n - 1

    more_message = String.new
    if items.size > last_item_n
      more_items_n = items.size - last_item_n
      more_message = "#{more_items_n.to_s} more like this &gt;&gt;"
    end

    # use a different template for images than text based links
    if related_class == 'StillImage'
      template_name = 'related_images_links'
    else
      template_name = 'related_items_links'
    end

    return render(:partial => "topics/#{template_name}",
                  :layout => :false,
                  :locals => { :related_class => related_class,
                    :items => items,
                    :end_range => end_range,
                    :more_message => more_message,
                    :source_item => source_item,
                    :last_item_n => last_item_n,
                    :relate_to_topic_id => relate_to_topic_id})
  end

  # does the current user have the admin role
  # on the site basket?
  def site_admin?
    @site = Basket.find_by_id(1)
    permit? "admin on :site" do
      return :true
    end
  end

end
