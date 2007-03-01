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
    link_to h(item.title), :controller => zoom_class_controller(item.class.name),
    :urlified_name => item.basket.urlified_name,
    :action => :show, :id => item
  end

  def link_to_contributions_of(user,zoom_class)
    link_to h(user.login), :controller => 'search',
    :urlified_name => 'site',
    :controller_name_for_zoom_class => zoom_class_controller(zoom_class),
    :action => :all, :contributor => user, :trailing_slash => true
  end

  def link_to_related_to_source(options={})
    link_to(options[:phrase], { :controller => 'search',
              :action => :all,
              :trailing_slash => true,
              :source_item => options[:source_item],
              :source_controller_singular => zoom_class_controller(options[:source_item_class]).singularize,
              :controller_name_for_zoom_class => zoom_class_controller(options[:related_class]),
            :urlified_name => 'site' }, { :class => 'small'})
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
    xml.tag!("dc:identifier", "http://#{request.host}#{url_for(:controller => zoom_class_controller(item.class.name), :action => 'show', :id => item, :format => nil, :urlified_name => @current_basket.urlified_name)}")
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

  # TODO: this attribute isn't coming over even though it's in the select
  # contribution_date = contributor.version_created_at.to_date
  # xml.tag!("dcterms:modified", contribution_date)
  def oai_dc_xml_dc_contributors_and_modified_dates(xml,item)
    item.contributors.each do |contributor|
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
          xml.tag!("dc:relation", "http://#{request.host}#{url_for(:controller => zoom_class_controller(zoom_class), :action => 'show', :id => related, :format => nil, :urlified_name => related.basket.urlified_name)}")
        end
      end
    else
      item.topics.each do |related|
          xml.tag!("dc:subject", related.title)
          xml.tag!("dc:relation", "http://#{request.host}#{url_for(:controller => :topics, :action => 'show', :id => related, :format => nil, :urlified_name => related.basket.urlified_name)}")
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
      format = item.original_file.content_type
    else
      format = item.content_type
    end
    xml.tag!("dc:format", format)
  end

  def non_dc_extended_content_field_xml(extended_content_hash,non_dc_extended_content_hash,field)
    # use xml_element_name, but append to non_dc_extended_content
    if !extended_content_hash[field]['xml_element_name'].blank?
      x = Builder::XmlMarkup.new
      if !extended_content_hash[field]['xml_element_name']['xsi_type'].blank?
        non_dc_extended_content += x.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'], "xsi:type".to_sym => extended_content_hash[field]['xml_element_name']['xsi_type'])
      else
        non_dc_extended_content += x.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'])
      end
    else
      non_dc_extended_content_hash[field] = extended_content_hash[field]
    end
  end

  def extended_content_hash_field_xml(xml,extended_content_hash,non_dc_extended_content_hash,field,re)
    if !extended_content_hash[field]['value'].blank? || !extended_content_hash[field].blank?
      if !extended_content_hash[field]['xml_element_name'].blank? && re.match(extended_content_hash[field]['xml_element_name'])
        # it's a dublin core tag, just spit it out
        # we allow for xsi:type specification
        if !extended_content_hash[field]['xml_element_name']['xsi_type'].blank?
          xml.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'], "xsi:type".to_sym => extended_content_hash[field]['xml_element_name']['xsi_type'])
        else
          xml.tag!(extended_content_hash[field]['xml_element_name'], extended_content_hash[field]['value'])
        end
      else
        non_dc_extended_content_field_xml(extended_content_hash,non_dc_extended_content_hash,field)
      end
    end
  end

  def oai_dc_xml_dc_extended_content(xml,item)
    # work through extended_content, see what should be it's own dc element
    # and what should go in a group dc:description
    temp_extended_content = item.extended_content
    extended_content_hash = XmlSimple.xml_in("<dummy>#{temp_extended_content}</dummy>", 'contentkey' => 'value', 'forcearray'   => false)

    non_dc_extended_content_hash = Hash.new
    re = Regexp.new("^dc")
    multi_re = Regexp.new("_multiple$")
    extended_content_hash.keys.each do |field|
      # condition that checks if this is a multiple field
      # if so move into it and does the following for each
      if multi_re.match(field)
        logger.debug("in multi")
        # value is going to be a hash like this:
        # "1" => {field_name => value}, "2" => ...
        # we want the first field name followed by a :
        # and all values, separated by spaces (for now)
        hash_of_values = extended_content_hash[field]
        hash_of_values.keys.each do |key|
          hash_of_values[key].keys.each do |subfield|
            extended_content_hash_field_xml(xml,hash_of_values[key],non_dc_extended_content_hash,subfield,re)
          end
        end
      else
        extended_content_hash_field_xml(xml,extended_content_hash,non_dc_extended_content_hash,field,re)
      end
    end

    if !non_dc_extended_content_hash.blank?
      xml.tag!("dc:description") do
        non_dc_extended_content_hash.each do |key, value|
          xml.tag!(key, value)
        end
      end
    end
  end

  # extended_content_xml_helpers
  def extended_content_field_xml_tag(options = {})
    begin
      xml = options[:xml]
      field = options[:field]
      value = options[:value] || nil
      xml_element_name = options[:xml_element_name] || nil
      xsi_type = options[:xsi_type] || nil

      # if we don't have xml_element_name, go with simplest case
      if xml_element_name.blank?
        xml.tag!(field, value)
      else
        # next simplest case, we have xml_element_name, but no xsi_type
        if xsi_type.blank?
          xml.tag!(field, value, :xml_element_name => xml_element_name )
        else
          xml.tag!(field, value, :xml_element_name => xml_element_name, :xsi_type => xsi_type)
        end
      end
    rescue
      logger.error("failed to format xml: #{$!.to_s}")
    end
  end

  # tag related helpers
  def link_to_tagged(tag,zoom_class)
    link_to(h(tag.name), { :controller => 'search', :action => 'all',
              :tag => tag,
              :trailing_slash => true,
              :controller_name_for_zoom_class => zoom_class_controller(zoom_class),
              :urlified_name => 'site' })
  end

  def tags_for(item)
    html_string = String.new
    if item.tags.size > 0
      html_string = "<p>Tags: "
      tag_count = 1
      item.tags.each do |tag|
        if item.tags.size != tag_count
          html_string += link_to_tagged(tag,item.class.name) +", "
        else
          html_string += link_to_tagged(tag,item.class.name)
        end
        tag_count += 1
      end
      html_string += "</p>"
    end
  end

  def tags_input_field(form,label_for)
    "<p><label for=\"#{label_for}\">Tags (separated by commas):</label>
                #{form.text_field :tag_list}</p>"
  end

  #---- related to extended_fields for either topic_types or content_types
  def display_xml_attributes(item)
    html_string = ""
    # TODO: these should have their order match the specified order for the item_type
    item.xml_attributes.each do |field_key, field_value|
      # we now handle multiples
      multi_re = Regexp.new("_multiple$")
      if multi_re.match(field_key)
        # value is going to be a hash like this:
        # "1" => {field_name => value}, "2" => ...
        # we want the first field name followed by a :
        # and all values, separated by spaces (for now)
        field_name = String.new
        field_values = Array.new
        field_value.keys.each do |subfield_key|
          field_hash = item.xml_attributes[field_key][subfield_key]
          field_hash.keys.each do |key|
            if field_name.blank?
              field_name = key.humanize
            end
            if !field_hash[key].blank? && !field_hash[key].to_s.match("xml_element_name")
              field_values << field_hash[key]
            end
          end
        end
        if !field_values.to_s.strip.blank?
          html_string += "<tr><td class=\"detail-extended-field-label\">#{field_name}:</td><td>#{field_values.to_sentence}</td></tr>\n"
        end
      else
        if !field_value.to_s.strip.blank? && !field_value.is_a?(Hash)
          html_string += "<tr><td class=\"detail-extended-field-label\">#{field_key.humanize}:</td><td>#{field_value}</td></tr>\n"
        end
      end
    end
    if !html_string.blank?
      html_string = "<table class=\"detail-extended-field-table\">\n<tbody>\n#{html_string}\n</tbody>\n</table>"
    end
    return html_string
  end

end
