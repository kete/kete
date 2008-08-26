# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ExtendedFieldsHelpers

  include ExtendedContentHelpers

  include OaiDcHelpers

  include ZoomHelpers

  def header_links_to_baskets
    html = '<ul id="basket-list" class="nav-list">'

    except_certain_baskets = @standard_baskets
    except_certain_baskets += [@current_basket] if @current_basket != @site_basket

    except_certain_baskets_args = { :conditions => ["id not in (?)", except_certain_baskets] }

    baskets_limit = 2

    total_baskets_count = Basket.count(except_certain_baskets_args)

    except_certain_baskets_args[:limit] = baskets_limit

    basket_count = 0
    Basket.find(:all, except_certain_baskets_args).each do |basket|
      basket_count += 1
      html += li_with_correct_class(basket_count) + link_to_index_for(basket) + '</li>'
    end

    if baskets_limit < total_baskets_count
      html += '<li>' + link_to_unless_current('more...',
                                              url_for(:urlified_name => @site_basket.urlified_name,
                                                      :controller => 'baskets' )) + '</li>'
    end

    html += '</ul>'
    if basket_count > 0
      return html
    else
      return ''
    end
  end

  def header_link_to_current_basket
    html = String.new
    html += ': ' + link_to_index_for(@current_basket, { :class => 'basket' }) if @current_basket != @site_basket
  end

  def search_link_to_searched_basket
    html = String.new
    html += ' ' + link_to_index_for(@current_basket, { :class => 'basket' }) if @current_basket != @site_basket
  end

  def link_to_index_for(basket, options = { })
    link_to basket.name, basket_index_url(basket.urlified_name), options
  end

  def header_browse_links
    html = '<li>'

    pre_text = String.new
    site_link_text = String.new
    current_basket_html = String.new
    if @current_basket != @site_basket
      pre_text = 'Browse: '
      site_link_text = @site_basket.name
      privacy_type = (@current_basket.private_default_with_inheritance? && permitted_to_view_private_items?) ? 'private' : nil
      current_basket_html = " or " + link_to_unless_current( @current_basket.name,
                                                            :controller => 'search',
                                                            :action => 'all',
                                                            :urlified_name => @current_basket.urlified_name,
                                                            :controller_name_for_zoom_class => 'topics',
                                                            :trailing_slash => true,
                                                            :privacy_type => privacy_type )
    else
      site_link_text = 'Browse'
    end

    html += pre_text + link_to_unless_current( site_link_text,
                                               :controller => 'search',
                                               :action => 'all',
                                               :urlified_name => @site_basket.urlified_name,
                                               :controller_name_for_zoom_class => 'topics',
                                               :trailing_slash => true ) + current_basket_html + '</li>'
  end

  def header_add_links
    return unless current_user_can_see_add_links?

    html = '<li>'

    pre_text = String.new
    site_link_text = String.new
    current_basket_html = String.new
    if @current_basket != @site_basket
      pre_text = 'Add item to '
      site_link_text = @site_basket.name
      current_basket_html = " or " + link_to_unless_current( @current_basket.name,
                                                            :controller => 'baskets',
                                                            :action => 'choose_type',
                                                            :urlified_name => @current_basket.urlified_name)
    else
      site_link_text = 'Add item'
    end

    html += pre_text + link_to_unless_current( site_link_text,
                                               :controller => 'baskets',
                                               :action => 'choose_type',
                                               :urlified_name => @site_basket.urlified_name) + current_basket_html + '</li>'
  end


  def render_baskets_as_menu
    html = '<ul id="sub-menu" class="menu basket-list-menu">'
    except_certain_baskets_args = { :conditions => ["id not in (?)", @standard_baskets] }

    basket_count = 0
    Basket.find(:all, except_certain_baskets_args).each do |basket|
      basket_count += 1
      if basket == @current_basket

        html += li_with_correct_class(basket_count) + link_to_index_for(basket)

        html += '<ul>'
        topic_count = 0

        order_with_inheritence = basket.settings[:side_menu_ordering_of_topics] || @site_basket.settings[:side_menu_ordering_of_topics]
        direction_with_inheritence = basket.settings[:side_menu_direction_of_topics] || @site_basket.settings[:side_menu_direction_of_topics]

        order = case order_with_inheritence
                when "alphabetical"
                  case direction_with_inheritence
                  when "reverse"
                    "title DESC"
                  else
                    "title ASC"
                  end
                else
                  case direction_with_inheritence
                  when "reverse"
                    "updated_at ASC"
                  else
                    "updated_at DESC"
                  end
                end

        if !basket.settings[:side_menu_number_of_topics].blank?
          limit = basket.settings[:side_menu_number_of_topics].to_i
        elsif !@site_basket.settings[:side_menu_number_of_topics].blank?
          limit = @site_basket.settings[:side_menu_number_of_topics].to_i
        else
          limit = 10
        end

        basket_topic_count = 0

        for topic in basket.topics.find(:all, :limit => limit, :order => order).reject { |t| t.disputed_or_not_available? }
          if topic != basket.index_topic
            html += li_with_correct_class(topic_count) + link_to_item(topic) + '</li>'
            basket_topic_count += 1
          end
        end

        if basket.topics.count > basket_topic_count && basket_topic_count > 0
          html += content_tag("li", link_to("More..",
                                            :controller => 'search',
                                            :action => 'all',
                                            :urlified_name => basket.urlified_name,
                                            :controller_name_for_zoom_class => 'topics'))
        end

        html += '</ul>'

      else
        html += li_with_correct_class(basket_count) + link_to_index_for(basket)
      end
      html += '</li>'
    end
    html += '</ul>'
  end

  def current_user_can_see_flagging?
    if @current_basket.settings[:show_flagging] == "at least moderator"
        can_see_flagging = logged_in? && @at_least_a_moderator
    else
        can_see_flagging = true
    end
    can_see_flagging
  end

  def current_user_can_see_add_links?
    if @current_basket.settings[:show_add_links] == "at least moderator"
        can_see_add_links = logged_in? && @at_least_a_moderator
    else
        can_see_add_links = true
    end
    can_see_add_links
  end

  def current_user_can_see_action_menu?
    if @current_basket.settings[:show_action_menu] == "at least moderator"
        can_see_action_menu = logged_in? && @at_least_a_moderator
    else
        can_see_action_menu = true
    end
    can_see_action_menu
  end

  def current_user_can_see_discussion?
    if @current_basket.settings[:show_discussion] == "at least moderator"
        can_see_discussion = logged_in? && @at_least_a_moderator
    else
        can_see_discussion = true
    end
    return_value = can_see_discussion
  end


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
      return link_to("Cancel", url_for(session[:return_to]))
    end
  end

  def link_to_item(item)
    link_to h(item.title), :controller => zoom_class_controller(item.class.name),
    :urlified_name => item.basket.urlified_name,
    :action => :show, :id => item
  end

  def url_for_contributions_of(user, zoom_class)
    url_for(:controller => 'search',
            :urlified_name => @site_basket.urlified_name,
            :controller_name_for_zoom_class => zoom_class_controller(zoom_class),
            :action => :all, :contributor => user, :trailing_slash => true, :only_path => false)
  end

  def link_to_contributions_of(user,zoom_class)
    link_to h(user.user_name), url_for_contributions_of(user, zoom_class)
  end

  def url_for_profile_of(user)
    url_for(:controller => 'account',
            :urlified_name => @site_basket.urlified_name,
            :action => :show, :id => user, :only_path => false)
  end

  def link_to_profile_for(user)
    link_to h(user.user_name), url_for_profile_of(user)
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
    return link_to("#{phrase}", :controller => zoom_class_controller(item_class), :action => :new, :relate_to_topic => options[:relate_to_topic])
  end

  def link_to_add_set_of_related_items(options={})
    return link_to(options[:phrase],
                   :controller => 'importers',
                   :action => 'new_related_set_from_archive_file',
                   :zoom_class => options[:zoom_class],
                   :relate_to_topic => options[:relate_to_topic])
  end

  def link_to_link_related_item(options={})
    link_to("link to existing #{zoom_class_humanize(options[:related_class]).downcase}", {
                     :controller => 'search',
                     :action => :find_related,
                     :related_class => options[:related_class],
                     :relate_to_topic => options[:relate_to_topic],
                     :function => "add" },
                     :popup => ['links', 'height=500,width=500,scrollbars=yes,top=100,left=100,resizable=yes'])
  end

  def link_to_unlink_related_item(options={})
    link_to("Unlink #{zoom_class_humanize(options[:related_class]).downcase}", {
                     :controller => 'search',
                     :action => :find_related,
                     :related_class => options[:related_class],
                     :relate_to_topic => options[:relate_to_topic],
                     :function => "remove" },
                     :popup => ['links', 'height=500,width=500,scrollbars=yes,top=100,left=100,resizable=yes'])
  end

  def link_to_restore_related_item(options={})
    link_to("Restore previously linked #{zoom_class_humanize(options[:related_class]).downcase}", {
                     :controller => 'search',
                     :action => :find_related,
                     :related_class => options[:related_class],
                     :relate_to_topic => options[:relate_to_topic],
                     :function => "restore" },
                     :popup => ['links', 'height=500,width=500,scrollbars=yes,top=100,left=100,resizable=yes'])
  end

  def item_related_topics_wrapper(options={})
    beginning_html = %q(
                    <div id="detail-linked">)
    if options[:topics].nil?
      beginning_html += "
                        <h3>This #{options[:class_phrase]} is not related to any topics at this time.</h3>"
    else
      beginning_html += "
                        <div class=\"secondary-content-section-wrapper-blue\">
                        <div id=\"related-link\" class=\"secondary-content-section\">
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
                        <div class="secondary-content-section-footer-wrapper"><div class="secondary-content-section-footer">&nbsp;</div></div>
                        </div>
                        </div>
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
        items = items.find_all_non_pending if items.size > 0
      else
        items = source_item.send('related_topics', :only_non_pending => true)
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
              :urlified_name => @site_basket.urlified_name,
              :privacy_type => get_acceptable_privacy_type(nil, "private") })
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
    "<div class=\"form-element\"><label for=\"#{label_for}\">Tags (separated by commas):</label>
                #{form.text_field :tag_list}</div>"
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
                  field_values[field_value_index] = mail_to(field_value,field_value, :encode => "hex")
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
                field_value = mail_to(field_value,field_value, :encode => "hex")
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
    # everything else is just related topics and comments
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
      item.comments.each do |related_item|
        items_to_rebuild << "Comment-#{related_item.id}"
      end
    end
    return items_to_rebuild.join(",")
  end

  # related to comments
  def show_comments_for(item)
    html_string = "<p>There are #{@comments.size} comments in this discussion.</p>\n<p>"

    logger.debug("what are comments: " + @comments.inspect)
    if @comments.size > 0
      html_string += "Read and "
    end

    html_string += link_to("join this discussion",
                           {:action => :new,
                             :controller => 'comments',
                             :commentable_id => item,
                             :commentable_type => item.class.name,
                             :commentable_private => (item.respond_to?(:private) && item.private?) ? 1 : 0
                           },
                           :method => :post)

    html_string += "</p>\n"

    if @comments.size > 0
      @comments.each do |comment|
        html_string += "<div class=\"comment-wrapper\"><h5>"
        html_string += "#{link_to_contributions_of(comment.creators.first,'Comment')}"
        html_string += " said "
        html_string += "<a name=\"comment-#{comment.id}\">#{h(comment.title)}</a>"
        html_string += "</h5>"

        #changed Steven Upritchard katipo.co.nz todo: clean this up
        #html_string += "<div class=\"comment-wrapper\">""<h5><a name=\"comment-#{comment.id}\">#{h(comment.title)}</a> by "
        #html_string += "#{link_to_contributions_of(comment.creators.first,'Comment')}</h5><div class=\"comment-content\">\n"


        html_string += "<div class=\"comment-content\">"

        if !comment.description.blank?
          html_string += "#{comment.description}\n"
        end

        tags_for_comment = tags_for(comment)
        if !tags_for_comment.blank?
          html_string += "#{tags_for_comment}\n"
        end
        html_string += pending_review(comment) + "\n"

        html_string += "<div class=\"comment-tools\">\n"
        html_string += flagging_links_for(comment,true,'comments')
        if logged_in? and @at_least_a_moderator
          html_string += "<ul><li>" + link_to("Edit",
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
                                            :id => comment,
                                            :authenticity_token => form_authenticity_token},
                                          :method => :post,
                                          :confirm => 'Are you sure?') + "</li>\n"
        end
        html_string += "</ul>\n</div></div></div>"
      end
      html_string += "<p>" + link_to("join this discussion",
                                     {:action => :new,
                                       :controller => 'comments',
                                       :commentable_id => item,
                                       :commentable_type => item.class.name,
                                       :commentable_private => (item.respond_to?(:private) && item.private?) ? 1 : 0,
                                       :authenticity_token => form_authenticity_token
                                     },
                                     :method => :post) + "</p>"
    end
    return html_string
  end

  def flagging_links_for(item, first = false, controller = nil)
    html_string = String.new
    if FLAGGING_TAGS.size > 0 and !item.already_at_blank_version?
      if first
        html_string = "                                        <ul><li class=\"first flag\">Flag as:</li>\n"
      else
        html_string = "                                         <ul><li class=\"flag\">Flag as:</li>\n"
      end
      html_string += "<li><ul>\n"
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
                                   :id => item,
                                   :version => item.version },
                                 :confirm => 'Remember, you may have the option to directly edit this item or alternatively discuss it. Are you sure you want to flag it instead?') + "</li>\n"
        else
          html_string += link_to(flag,
                                 { :action => 'flag_form',
                                   :flag => flag,
                                   :id => item,
                                   :version => item.version },
                                 :confirm => 'Remember, you may have the option to directly edit this item or alternatively discuss it. Are you sure you want to flag it instead?') + "</li>\n"
        end

        flag_count += 1
      end
      html_string += "                                            </ul>
                                        </li></ul>\n"
    end
  end

  def pending_review(item)
    html_string = String.new
    if item.disputed?
      html_string = "<h4>Review Pending: "
      privacy_type = item.respond_to?(:private) && item.private? ? "private" : "public"
      if !item.already_at_blank_version?
        html_string += "currently reverted to non-disputed #{privacy_type} version \# #{item.version}"
      elsif
        html_string += "currently no non-disputed #{privacy_type} versions of this item. Details of the #{privacy_type} version of this item are not being displayed at this time."
      end
      html_string += "</h4>"
    end
    return html_string
  end

  def link_to_preview_of(item, version, check_permission = true)
    version_number = 0
    link_text = 'preview'
    begin
      version_number = version.version
    rescue
      link_text = '#' + version
      version_number = version.to_i
    end

    if check_permission == false or can_preview?(:item => item, :version_number => version_number)
      link_to link_text, url_for_preview_of(item, version_number)
    else
      'not available'
    end
  end

  def url_for_preview_of(item, version_number)
    url_for(:controller => zoom_class_controller(item.class.name),
            :urlified_name => item.basket.urlified_name,
            :action => 'preview',
            :id => item.id,
            :version => version_number)
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

  # we use this in imports, too
  def topic_type_select_with_indent(object, method, collection, value_method, text_method, current_value, html_options={ })
    result = "<select name=\"#{object}[#{method}]\" id=\"#{object}_#{method}\""
    html_options.each do |key, value|
        result << ' ' + key.to_s + '="' + value.to_s + '"'
    end
    result << ">\n"
    for element in collection
      indent_string = String.new
        element.level.times { indent_string += "&nbsp;" }
        if current_value == element.send(value_method)
          result << "<option value='#{ element.send(value_method)}' selected='selected'>#{indent_string}#{element.send(text_method)}</option>\n"
        else
          result << "<option value='#{element.send(value_method)}'>#{indent_string}#{element.send(text_method)}</option>\n"
        end
    end
    result << "</select>\n"
    return result
  end

  def load_styles(theme)
    theme_styles = Array.new
    theme_styles_path = theme + '/stylesheets/'
    theme_styles_full_path = THEMES_ROOT + '/' + theme_styles_path
    theme_styles_dir = Dir.new(theme_styles_full_path)
    theme_styles_dir.each do |file|
      file_full_path = theme_styles_full_path + file.to_s
      if !File.directory?(file_full_path) and File.extname(file_full_path) == '.css'
        web_root_to_file = '/' + THEMES_DIR_NAME + '/' + theme_styles_path + file
        theme_styles << web_root_to_file
      end
    end
    theme_styles
  end

  # Kieran Pilkington, 2008/07/28
  # DEPRECATED, points to cache_with_privacy
  def cache_if_public(item, name = {}, options = nil, &block)
    cache_with_privacy(item, name, options, &block)
  end

  # Kieran Pilkinton, 2008/07/28
  # Cache block with the privacy value
  # Different blocks have different values for public and private version
  # If something shares data, just use rails cache method
  # item can be nil
  # but this assumes that item is not nil when item is private
  def cache_with_privacy(item, name = {}, options = nil, &block)
    privacy_value = (!item.blank? && item.respond_to?(:private) && item.private?) ? "private" : "public"
    name.each { |key,value| name[key] = "#{value}_#{privacy_value}" }

    # item is nil when we are loading from cache,
    # so always use params[:id]
    # strip out title from passed id
    # (.to_i will only return 123 when passed id is "123-some-title")
    # if we have an id for this page
    name[:id] = params[:id].to_i unless params[:id].blank?
    cache(name, options, &block)
  end

  # Check if privacy controls should be displayed?
  def show_privacy_controls?
    @current_basket.show_privacy_controls_with_inheritance?
  end

  def show_privacy_search_controls?
    if @current_basket == @site_basket
      # note that it has to be "== true" in combination with ||, or you will get unexpected results when show_privacy_controls is not nil and == false
      (@site_basket.show_privacy_controls == true or Basket.privacy_exists)
    else
      @current_basket.show_privacy_controls_with_inheritance?
    end
  end

  # Check whether to show privacy controls for an item
  def show_privacy_controls_for?(item)
    show_privacy_controls? &&
      ( item.new_record? ||
        current_user_can_see_private_files_in_basket?(item.basket) ||
        @current_user == item.creator )
  end

end
