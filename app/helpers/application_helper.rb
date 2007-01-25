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

  # TODO: this needs basket.urlified_name
  def link_to_item(item)
    link_to h(item.title), :controller => zoom_class_controller(item.class.name),
    :urlified_name => item.basket.urlified_name,
    :action => :show, :id => item.id
  end

  def link_to_related_to_source(options={})
    link_to(options[:phrase], { :controller => 'search', :source_item => options[:source_item], :source_item_class => options[:source_item_class], :current_class => options[:related_class], :urlified_name => 'site' }, { :class => 'small'})
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
                        <h3>Related Topics:</h3>"
    end
    beginning_html +=%q(
                        <div id="pipe-list">)

    middle_html = String.new
    if !options[:topics].nil?
      middle_html = related_items_links(:source_item => options[:source_item], :source_item_class => options[:source_item_class], :items => options[:topics], :related_class => 'Topic', :pipe_list => :true )
    end

    end_html = %q(
                        </div>
                        <div class="cleaner">&nbsp;</div>
                </div>)
    return beginning_html + middle_html + end_html
  end

  def related_items_links(options={})
    source_item = options[:source_item]
    source_item_class = options[:source_item_class]
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
                    :source_item_class => source_item_class,
                    :last_item_n => last_item_n,
                    :pipe_list => options[:pipe_list],
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

  # TODO: this is duplicated in application.rb, fix
  def user_to_dc_creator_or_contributor(user)
    user.login
  end

#### oai dublin core xml helpers
  def oai_dc_xml_request(xml,item)
    xml.request(request.protocol + request.host + request.request_uri, :verb => "GetRecord", :identifier => "#{ZoomDb.zoom_id_stub}#{@current_basket.urlified_name}:#{item.class.name}:#{item.id}", :metadataPrefix => "oai_dc")
  end

  def oai_dc_xml_oai_identifier(xml,item)
    xml.identifier("#{ZoomDb.zoom_id_stub}#{@current_basket.urlified_name}:#{item.class.name}:#{item.id}")
  end

  def oai_dc_xml_dc_identifier(xml,item)
    xml.tag!("dc:identifier", "http://#{request.host}#{url_for(:controller => zoom_class_controller(item.class.name), :action => 'show', :id => item.id, :format => nil, :urlified_name => @current_basket.urlified_name)}")
  end

  def oai_dc_xml_dc_title(xml,item)
    xml.tag!("dc:title", item.title)
  end

  def oai_dc_xml_dc_publisher(xml,publisher = nil)
    # this website is the publisher by default
    if publisher.nil?
      xml.tag!("dc:publisher", @request.host)
    else
      xml.tag!("dc:publisher", publisher)
    end
  end

  def oai_dc_xml_dc_description(xml,description)
    xml.tag!("dc:description", description)
  end

  def oai_dc_xml_dc_creators_and_date(xml,item)
    item_created = item.created_at.to_date
    xml.tag!("dc:date", item_created)
    item.creators.each do |creator|
      xml.tag!("dc:creator", user_to_dc_creator_or_contributor(creator))
    end
  end

  def oai_dc_xml_dc_contributors_and_modified_dates(xml,item)
    item.contributors.each do |contributor|
      contribution_date = contributor.version_created_at.to_date
      xml.tag!("dcterms:modified", contribution_date)
      xml.tag!("dc:contributor", user_to_dc_creator_or_contributor(contributor))
    end
  end

  def oai_dc_xml_dc_relations_and_subjects(xml,item)
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
          xml.tag!("dc:relation", "http://#{request.host}#{url_for(:controller => zoom_class_controller(zoom_class), :action => 'show', :id => related.id, :format => nil, :urlified_name => related.basket.urlified_name)}")
        end
      end
    else
      item.topics.each do |related|
          xml.tag!("dc:subject", related.title)
          xml.tag!("dc:relation", "http://#{request.host}#{url_for(:controller => :topics, :action => 'show', :id => related.id, :format => nil, :urlified_name => related.basket.urlified_name)}")
      end
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
      format = item.original_file.content_type
    else
      format = item.content_type
    end
    xml.tag!("dc:format", format)
  end

  def oai_dc_xml_dc_topic_content(xml,topic)
    # work through content, see what should be it's own dc element
    # and what should go in a group dc:description
    temp_content = topic.content
    content_hash = XmlSimple.xml_in("<dummy>#{temp_content}</dummy>", 'contentkey' => 'value', 'forcearray'   => false)

    non_dc_content_hash = Hash.new
    re = Regexp.new("^dc")
    content_hash.keys.each do |field|
      if !content_hash[field]['xml_element_name'].blank? && re.match(content_hash[field]['xml_element_name'])
        # it's a dublin core tag, just spit it out
        xml.tag!(content_hash[field]['xml_element_name'], content_hash[field]['value'])
      elsif !content_hash[field]['xml_element_name'].blank?
        # use xml_element_name, but append to non_dc_content
        x = Builder::XmlMarkup.new
        non_dc_content += x.tag!(content_hash[field]['xml_element_name'], content_hash[field]['value'])
      else
        non_dc_content_hash[field] = content_hash[field]['value']
      end
    end

    if !non_dc_content_hash.blank?
      xml.tag!("dc:description") do
        non_dc_content_hash.each do |key, value|
          xml.tag!(key, value)
        end
      end
    end
  end
end
