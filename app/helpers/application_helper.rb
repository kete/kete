# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ExtendedFieldsHelpers

  include ExtendedContentHelpers

  include OaiDcHelpers

  include ZoomHelpers

  # TODO: may want to replace this with better history plugin
  def link_to_last_stored_location
    if session[:return_to_title].blank?
      return link_to("&lt;&lt; Back to Kete Home", '/')
    else
      return link_to("&lt;&lt; Back to \"#{session[:return_to_title]}\"", session[:return_to])
    end
  end

  def link_to_cancel
    if session[:return_to].blank?
      return link_to("Cancel", :action => 'list')
    else
      return link_to("Cancel", session[:return_to])
    end
  end

  def link_to_item(item)
    link_to h(item.title), :controller => zoom_class_controller(item.class.name),
    :urlified_name => item.basket.urlified_name,
    :action => :show, :id => item
  end

  def link_to_contributions_of(user,zoom_class)
    link_to h(user.user_name), :controller => 'search',
    :urlified_name => @site_basket.urlified_name,
    :controller_name_for_zoom_class => zoom_class_controller(zoom_class),
    :action => :all, :contributor => user, :trailing_slash => true
  end

  def link_to_profile_for(user)
    link_to h(user.user_name), :controller => 'account',
    :urlified_name => @site_basket.urlified_name,
    :action => :show, :id => user
  end

  def link_to_related_to_source(options={})
    link_to(options[:phrase], { :controller => 'search',
              :action => :all,
              :trailing_slash => true,
              :source_item => options[:source_item],
              :source_controller_singular => zoom_class_controller(options[:source_item_class]).singularize,
              :controller_name_for_zoom_class => zoom_class_controller(options[:related_class]),
              :urlified_name => @site_basket.urlified_name }, { :class => 'small'})
  end

  def link_to_add_item(options={})
    phrase = options[:phrase]
    item_class = options[:item_class]

    phrase += ' ' + zoom_class_humanize(item_class)

    if @current_basket != @site_basket
      phrase += ' in ' + @current_basket.name
    end

    return link_to(phrase, :controller => zoom_class_controller(item_class), :action => :new)
  end

  def link_to_add_related_item(options={})
    phrase = options[:phrase]
    item_class = options[:item_class]
    return link_to("#{phrase} #{zoom_class_humanize(item_class).downcase}", :controller => zoom_class_controller(item_class), :action => :new, :relate_to_topic => options[:relate_to_topic])
  end

  def link_to_link_related_item(options={})
    phrase = options[:phrase]
    item_class = options[:item_class]
    return link_to("#{phrase} #{zoom_class_humanize(item_class).downcase}", {
                     :controller => 'search',
                     :action => :find_related,
                     :related_class => options[:related_class],
                     :relate_to_topic => options[:relate_to_topic] },
                   :popup => ['links', 'height=300,width=740,scrollbars=yes,top=100,left=100,resizable=yes'])
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
                        <div id="related_topics">)

    middle_html = String.new
    if !options[:topics].blank?
      middle_html = related_items_links(:source_item => options[:source_item], :related_class => 'Topic', :items => options[:topics], :pipe_list => :true )
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

    items = Array.new
    if options[:items].nil?
      if related_class != 'Topic'
        items = source_item.send(related_class.tableize)
      else
        items = source_item.send('related_topics')
      end
    else
      items = options[:items]
    end

    relate_to_topic = source_item.class.name == 'Topic' ? source_item : nil

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

    render :partial => "topics/#{template_name}",
    :locals => { :related_class => related_class,
      :items => items,
      :end_range => end_range,
      :more_message => more_message,
      :source_item => source_item,
      :last_item_n => last_item_n,
      :pipe_list => options[:pipe_list],
      :relate_to_topic => relate_to_topic }
  end

  # tag related helpers
  def link_to_tagged(tag,zoom_class)
    link_to(h(tag.name), { :controller => 'search', :action => 'all',
              :tag => tag,
              :trailing_slash => true,
              :controller_name_for_zoom_class => zoom_class_controller(zoom_class),
              :urlified_name => @site_basket.urlified_name })
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
    html_string = String.new

    if item.xml_attributes
      # the outermost hash is keyed by the field's position
      # i.e. "1" => {"some_field" => "some_field_value"}, "2" =>...
      # so you have to go down one to get the actual fields
      item_xml_hash = item.xml_attributes
      item_xml_array = item_xml_hash.sort
      item_xml_array.each do |field_array|
        subhash = item_xml_hash[field_array[0]]
        subhash.each do |field_key, field_value|
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
              field_hash = item_xml_hash[field_array[0]][field_key][subfield_key]
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
              field_value_index = 0
              field_values.each do |field_value|
                if field_value =~ /^\w+:\/\/[^ ]+/
                  # this is a url protocal of somesort, make link
                  field_values[field_value_index] = link_to(field_value,field_value)
                elsif field_value =~ /^\w+[^ ]*\@\w+\.\w/
                  field_values[field_value_index] = mail_to(field_value,field_value, :encode => "javascript")
                else
                  field_values[field_value_index] = sanitize(field_value)
                end
                field_value_index += 1
              end
              html_string += "<tr><td class=\"detail-extended-field-label\">#{field_name}:</td><td>#{field_values.to_sentence}</td></tr>\n"
            end
          else
            if !field_value.to_s.strip.blank? && !field_value.is_a?(Hash) && field_key != 'email_visible'
              if field_value =~ /^\w+:\/\/[^ ]+/
                # this is a url protocal of somesort, make link
                field_value = link_to(field_value,field_value)
              elsif field_value =~ /^\w+[^ ]*\@\w+\.\w/
                field_value = mail_to(field_value,field_value, :encode => "javascript")
              else
                field_value = sanitize(field_value)
              end
              html_string += "<tr><td class=\"detail-extended-field-label\">#{field_key.humanize}:</td><td>#{field_value}</td></tr>\n"
            end
          end
        end
      end
      if !html_string.blank?
        html_string = "<table class=\"detail-extended-field-table\" summary=\"Extended details\">\n<tbody>\n#{html_string}\n</tbody>\n</table>"
      end
    end
    return html_string
  end

  #---- end related to extended_fields for either topic_types or content_types

  # return an array of hashes of related items
  # where class is the key
  # and id is the value
  def items_to_rebuild(item)
    # first entry is self
    items_to_rebuild = [ "#{item.class.name}-#{item.id}" ]

    # grab all zoom_classes for topics
    # everything else is just related topics
    if item.class.name == 'Topic'
      ZOOM_CLASSES.each do |zoom_class|
        if zoom_class == 'Topic'
          item.related_topics.each do |related_topic|
            items_to_rebuild << "Topic-#{related_topic.id}"
          end
        else
          item.send(zoom_class.tableize).each do |related_item|
            items_to_rebuild << "#{zoom_class}-#{related_item.id}"
          end
        end
      end
    else
      item.topics.each do |related_item|
        items_to_rebuild << "Topic-#{related_item.id}"
      end
    end
    return items_to_rebuild.join(",")
  end

  # related to comments
  def show_comments_for(item)
    html_string = "<p>There are #{@comments.size} comments in this discussion.</p>\n<p>"

    if @comments.size > 0
      html_string += "Read and "
    end

    html_string += link_to("join this discussion",
                           {:action => :new,
                             :controller => 'comments',
                             :commentable_id => item,
                             :commentable_type => item.class.name
                           },
                           :method => :post)

    html_string += "</p>\n"

    if @comments.size > 0
      @comments.each do |comment|
        html_string += "<h5><a name=\"comment-#{comment.id}\">#{h(comment.title)}</a> by "
        html_string += "#{link_to_contributions_of(comment.creators.first,'Comment')}</h5>\n"
        if !comment.description.blank?
          html_string += "#{comment.description}\n"
        end
        tags_for_comment = tags_for(comment)
        if !tags_for_comment.blank?
          html_string += "#{tags_for_comment}\n"
        end
        html_string += pending_review(comment) + "\n"

        html_string += "<div class=\"comment-tools\">
                                <ul>\n"
        html_string += flagging_links_for(comment,true,'comments')
        if logged_in? and @at_least_a_moderator
          html_string += "<li>" + link_to("Edit",
                                          :controller => 'comments',
                                          :action => :edit,
                                          :id => comment) + "</li>\n"
          html_string += "<li>" + link_to("History",
                                          :controller => 'comments',
                                          :action => :history,
                                          :id => comment) + "</li>\n"
          html_string += "<li>" + link_to("Delete",
                                          {:action => :destroy,
                                            :controller => 'comments',
                                            :id => comment},
                                          :method => :post,
                                          :confirm => 'Are you sure?') + "</li>\n"
        end
        html_string += "<\ul>\n</div>"
      end
      html_string += "<p>" + link_to("join this discussion",
                                     {:action => :new,
                                       :controller => 'comments',
                                       :commentable_id => item,
                                       :commentable_type => item.class.name
                                     },
                                     :method => :post) + "</p>"
    end
    return html_string
  end

  def flagging_links_for(item, first = false, controller = nil)
    html_string = String.new
    if FLAGGING_TAGS.size > 0
      if first
        html_string = "                                         <li class=\"first\">Flag as:\n"
      else
        html_string = "                                         <li>Flag as:\n"
      end
      html_string += "<ul>\n"
      flag_count = 1
      FLAGGING_TAGS.each do |flag|
        if flag_count == 1
          html_string += "<li class=\"first\">"
        else
          html_string += "<li>"
        end
        if !controller.nil?
          html_string += link_to(flag,
                                 { :controller => controller,
                                   :action => 'flag_form',
                                   :flag => flag,
                                   :id => item },
                                 :confirm => 'Remember, you may have the option to directly edit this item or alternatively discuss it. Are you sure you want to flag it instead?') + "</li>\n"
        else
          html_string += link_to(flag,
                                 { :action => 'flag_form',
                                   :flag => flag,
                                   :id => item },
                                 :confirm => 'Remember, you may have the option to directly edit this item or alternatively discuss it. Are you sure you want to flag it instead?') + "</li>\n"
        end

        flag_count += 1
      end
      html_string += "                                            </ul>
                                        </li>\n"
    end
  end

  def reverted?(item)
    item.version != item.versions.last.version
  end

  def disputed?(item)
    item.versions.last.tags.size > 0
  end

  def pending_review(item)
    html_string = String.new
    if disputed?(item)
      html_string = "<h4>Review Pending: "
      if reverted?(item)
        html_string += "currently reverted to non-disputed version \# #{item.version}"
      else
        html_string += "displaying version flagged as "
        tag_names = Array.new
        item.versions.last.tags.each do |tag|
          tag_names << tag.name
        end
        html_string += tag_names.to_sentence
      end
    end
    return html_string
  end

  def link_to_preview_of(item, version)
    link_to "preview",
    :controller => zoom_class_controller(item.class.name),
    :urlified_name => item.basket.urlified_name,
    :action => :preview,
    :id => item,
    :version => version.version
  end

  def li_with_correct_class(count)
    html_string = "<li"
    if count == 1
      html_string += ' class="first"'
    end
    html_string += ">"
  end

  def link_to_original_of(item, phrase)
    if DOWNLOAD_WARNING.blank?
      link_to phrase, item.public_filename
    else
      link_to phrase, item.public_filename, :confirm => DOWNLOAD_WARNING
    end
  end

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
