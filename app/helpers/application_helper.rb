# Controls needed for Gravatar support throughout the site
require 'avatar/view/action_view_support'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ExtendedFieldsHelpers

  include ExtendedContentHelpers

  include OaiDcHelpers

  include ZoomHelpers

  # Controls needed for Gravatar support throughout the site
  include Avatar::View::ActionViewSupport
  def avatar_for(user, options = {})
    image_dimension = IMAGE_SIZES[:small_sq].gsub(/(!|>|<)/, '').split('x').first.to_i
    default_options = { :width => image_dimension, :height => image_dimension, :alt => "#{user.user_name}'s Avatar. " }
    options = default_options.merge(options)

    return nil if options[:return_portrait] && (!ENABLE_USER_PORTRAITS || user.portraits.empty?)

    if ENABLE_USER_PORTRAITS && !user.portraits.empty? && !user.portraits.first.thumbnail_file.file_private
      if options[:return_portrait]
        return user.portraits.first
      else
        return image_tag(user.portraits.first.thumbnail_file.public_filename, options)
      end
    elsif ENABLE_USER_PORTRAITS && !ENABLE_GRAVATAR_SUPPORT
      return image_tag('no-avatar.png', options)
    end

    if ENABLE_GRAVATAR_SUPPORT
      return avatar_tag(user, { :size => 50, :rating => 'G', :gravatar_default_url => "#{SITE_URL}images/no-avatar.png" }, options)
    end

    return ''
  end

  # Adds the necessary javascript to update a div with the id of user_avat
  def avatar_updater_js(options = {})
    options = options.merge({ :email_id => 'user_email', :avatar_id => 'user_avatar_img', :spinner_id => 'user_avatar_spinner' })
    javascript_tag("
      $('#{options[:email_id]}').observe('blur', function(event) {
        new Ajax.Request('#{url_for(:controller => 'account', :action => 'fetch_gravatar')}', {
          method: 'get',
          parameters: { email: $('#{options[:email_id]}').value, avatar_id: '#{options[:avatar_id]}' },
          onLoading: function(loading) { $('#{options[:spinner_id]}').show(); },
          onComplete: function(complete) { $('#{options[:spinner_id]}').hide(); }
        });
      });
    ")
  end

  def page_keywords
    return DEFAULT_PAGE_KEYWORDS if current_item.nil? || current_item.tags.blank?
    current_item.tags.join(",").gsub(" ", "_").gsub("\"", "")
  end

  def page_description
    return DEFAULT_PAGE_DESCRIPTION if current_item.nil?
    description_text = (current_item.respond_to?(:short_summary) && !current_item.short_summary.blank?) ? current_item.short_summary : current_item.description
    return DEFAULT_PAGE_DESCRIPTION if description_text.blank?
    strip_tags(truncate(description_text, 180)).gsub("\"", "").squish
  end

  def header_links_to_baskets
    html = '<ul id="basket-list" class="nav-list">'

    except_certain_baskets = @standard_baskets
    except_certain_baskets += [@current_basket] if @current_basket != @site_basket

    except_certain_baskets_args = { :conditions => ["id not in (?) AND status = 'approved'", except_certain_baskets] }

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
                                                      :controller => 'baskets' ), {:tabindex => '2'}) + '</li>'
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
    html += ': ' + link_to_index_for(@current_basket, { :class => 'basket', :tabindex => '2' }) if @current_basket != @site_basket
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
                                                            {:controller => 'search',
                                                            :action => 'all',
                                                            :urlified_name => @current_basket.urlified_name,
                                                            :controller_name_for_zoom_class => 'topics',
                                                            :trailing_slash => true,
                                                            :privacy_type => privacy_type}, {:tabindex => '2'} )
    else
      site_link_text = 'Browse'
    end

    html += pre_text + link_to_unless_current( site_link_text,
                                               {:controller => 'search',
                                               :action => 'all',
                                               :urlified_name => @site_basket.urlified_name,
                                               :controller_name_for_zoom_class => 'topics',
                                               :trailing_slash => true}, {:tabindex => '2'} ) + current_basket_html + '</li>'
  end

  def header_add_links(options={})
    return unless current_user_can_see_add_links?
    options = { :link_text => 'Add Item' }.merge(options)
    link_text = options.delete(:link_text)
    li_class = options.delete(:class) || ''
    html = "<li class='#{li_class}'>"
    html += link_to_unless_current(link_text,
                                   { :controller => 'baskets',
                                     :action => 'choose_type',
                                     :urlified_name => @current_basket.urlified_name }.merge(options),
                                   { :tabindex => '2' })
    html += '</li>'
  end

  def users_baskets_list(user=current_user, options ={})
    # if the user is the current user, use the basket_access_hash instead of fetching them again
    @baskets = (user == current_user) ? @basket_access_hash : user.basket_permissions

    row1 = 'user_basket_list_row1'
    row2 = 'user_basket_list_row2'
    css_class = row1

    if user == current_user || @site_admin
      Basket.find_all_by_status_and_creator_id('requested', user).each do |basket|
        @baskets << [basket.urlified_name, nil] if @baskets[basket.urlified_name.to_sym].blank?
      end
    end

    html = String.new
    @baskets.each do |basket_name, role|
      basket = Basket.find_by_urlified_name(basket_name.to_s)
      next unless user == current_user || current_user_can_see_memberlist_for?(basket)
      pending = (basket.status == 'requested') ? " (pending)" : ''
      link = link_to(basket.name + pending, basket_index_url(:urlified_name => basket_name))
      link += " - #{role[:role_name].humanize}" if options[:show_roles] && !role.blank?
      basket_options = options[:show_options] ? link_to_actions_available_for(basket, options) : ''
      basket_options = '<div class="profile_basket_options">[<ul>' + basket_options + '</ul>]</div>' unless basket_options.blank?
      html += content_tag('li', basket_options + link, :class => css_class)
      css_class = css_class == row1 ? row2 : row1
    end
    html
  end

  def header_add_basket_link
    return unless current_user_can_add_or_request_basket?

    if basket_policy_request_with_permissions?
      basket_text = 'Request basket'
    else
      basket_text = 'Add basket'
    end

    link_to_unless_current( basket_text,
                            :controller => 'baskets',
                            :action => 'new',
                            :urlified_name => @site_basket.urlified_name)
  end

  def render_baskets_as_menu
    html = '<ul id="sub-menu" class="menu basket-list-menu">'
    except_certain_baskets_args = { :conditions => ["id not in (?) AND status = 'approved'", @standard_baskets] }

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
                                            {:controller => 'search',
                                            :action => 'all',
                                            :urlified_name => basket.urlified_name,
                                            :controller_name_for_zoom_class => 'topics'},
                                            {:tabindex => '2'}))
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

  def link_to_members_of(basket, options={})
    options = { :viewable_text => "Members",
                :unavailable_text => "" }.merge(options)
    if current_user_can_see_memberlist_for?(basket)
      content_tag("li", link_to(options[:viewable_text],
                                :urlified_name => basket.urlified_name,
                                :controller => 'members',
                                :action => 'list'),
                        :class => options[:class] )
    elsif !options[:unavailable_text].blank?
      content_tag("li", options[:unavailable_text],
                        :class => options[:class])
    else
      ''
    end
  end

  def link_to_membership_request_of(basket, options={})
    return '' unless logged_in?

    options = { :join_text => "Join",
                :request_text => "Request membership",
                :closed_text => "",
                :as_list_element => true,
                :plus_divider => "",
                :pending_text => "Membership pending",
                :rejected_text => "Membership rejected",
                :current_role => "You're a |role|.",
                :leave_text => "Leave" }.merge(options)

    show_roles = options[:show_roles].nil? ? true : options[:show_roles]

    location_hash = { :urlified_name => basket.urlified_name,
                      :controller => 'members',
                      :action => 'join' }

    html = String.new

    if @basket_access_hash[basket.urlified_name.to_sym].blank?
      case basket.join_policy_with_inheritance
      when 'open'
        html += link_to(options[:join_text], location_hash)
      when 'request'
        html += link_to(options[:request_text], location_hash)
      else
        return '' if options[:closed_text].blank?
        html += options[:closed_text]
      end
    else
      role = @basket_access_hash[basket.urlified_name.to_sym][:role_name].humanize
      case role
      when "Membership requested"
        html += options[:pending_text]
      when "Membership rejected"
        html += options[:rejected_text]
      else
        html += options[:current_role].gsub('|role|', role) if show_roles
        # no one can remove themselves from the site basket
        # and there needs to be at least one basket admin remaining if the user removed him/herself
        if basket != @site_basket && @current_basket.more_than_one_basket_admin?
          html += " " + link_to(options[:leave_text], location_hash.merge({:action => 'remove', :id => current_user}))
        end
      end
    end

    html = "<li class='#{options[:class]}'>#{html}</li>" if !html.blank? && options[:as_list_element]
    html += options[:plus_divider]
  end

  def link_to_basket_contact_for(basket, include_name = true)
    link_text = 'Contact'
    link_text += ' ' + basket.name if include_name
    link_to link_text, basket_contact_path(:urlified_name => basket.urlified_name)
  end

  def link_to_actions_available_for(basket, options={})
    options[:class] = 'first'
    html = ''
    html += link_to_membership_request_of(basket, options)
    options[:class] = nil unless html.blank?
    html += link_to_members_of(basket, options)
    html += "<li>" + link_to_basket_contact_for(basket, false) + "</li>" if @current_basket.allows_contact_with_inheritance?
    html
  end

  def link_to_cancel(from_form = "")
    html = "<div id=\"cancel#{from_form}\" style=\"display:inline\">"
    if session[:return_to].blank?
      html += link_to("Cancel", :action => 'list', :tabindex => '1')
    else
      html += link_to("Cancel", url_for(session[:return_to]), :tabindex => '1')
    end
    html += "</div>"
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

  def link_to_contributions_of(user, zoom_class, options = {})
    if options[:with_avatar]
      display_html = avatar_for(user, { :class => 'user_contribution_link_avatar' })
      display_html += h(user.user_name)
      display_html += '<div class="clear"></div>'
    else
      display_html = h(user.user_name)
    end
    link_to display_html, url_for_contributions_of(user, zoom_class)
  end

  def stylish_link_to_contributions_of(user, zoom_class, options = {})
    options = { :with_avatar => true }.merge(options)
    div_classes = (['stylish_user_contribution_link'] + options[:additional_classes].to_a).flatten.compact.join(' ')
    display_html = "<div class=\"#{div_classes}\">"
    if options[:with_avatar]
      avatar = avatar_for(user)
      display_html += '<div class="stylish_user_contribution_link_avatar">' + avatar_for(user) + '</div>' unless avatar.blank?
    end
    user_link = link_to(h(user.user_name), url_for_contributions_of(user, zoom_class))
    link_text = (options[:link_text] || user_link).gsub('|user_name_link|', user_link)
    display_html += content_tag('div', link_text, :class => 'stylish_user_contribution_link_extra')
    display_html += options[:additional_html] if options[:additional_html]
    display_html += '<div style="clear:both;"></div>'
    display_html += '</div>'
    display_html
  end

  def add_to_stylish_display_with(content)
    "<div class=\"stylish_user_contribution_link_extra\">#{content}</div>"
  end

  def url_for_profile_of(user)
    url_for(:controller => 'account',
            :urlified_name => @site_basket.urlified_name,
            :action => :show, :id => user, :only_path => false)
  end

  def link_to_profile_for(user, phrase = nil)
    phrase ||= h(user.user_name)
    link_to phrase, url_for_profile_of(user)
  end

  def link_to_add_item(options={})
    phrase = options[:phrase]
    item_class = options[:item_class]

    phrase += ' ' + zoom_class_humanize(item_class)

    if @current_basket != @site_basket
      phrase += ' in ' + @current_basket.name
    end

    return link_to(phrase, {:controller => zoom_class_controller(item_class), :action => :new}, :tabindex => '1')
  end

  #
  # START RELATED ITEM HELPERS
  #

  # Public items need to be sorted based on the acts_as_list position in the database so
  # we can't use zebra to find public items in this case, so pull it from the database
  def public_related_items_for(item, options={})
    @items = Hash.new
    item_classes = options[:topics_only] ? ['Topic'] : ITEM_CLASSES
    item_classes.each do |item_class|
      if options[:count_only]
        items = find_related_items_for(item, item_class, { :start_record => nil, :end_record => nil, :dont_parse_results => true })
        @items[item_class] = items.size
      else
        if item_class != 'Topic' || options[:topics_only]
          items = item.send(item_class.tableize)
          items = items.find_all_public_non_pending if items.size > 0
        else
          items = item.related_topics(:only_non_pending => true)
        end
        @items[item_class] = items
      end
    end
    @items
  end

  # We use a method in lib/zoom_search.rb to find all private items the current user has access to
  # (should be faster than a bunch of mysql queries - might be an interesting thing to benchmark)
  def private_related_items_for(item, options={})
    @items = Hash.new
    item_classes = options[:topics_only] ? ['Topic'] : ITEM_CLASSES
    item_classes.each do |item_class|
      items = find_private_related_items_for(item, item_class, { :start_record => nil, :end_record => nil, :dont_parse_results => options[:count_only] })
      @items[item_class] = options[:count_only] ? items.size : items
    end
    @items
  end

  # Link to the related items of a certain item
  def link_to_related_items_of(item, zoom_class, options={}, location={})
    options = { :link_text => "View items related to #{item.title}" }.merge(options)
    location = { :urlified_name => @site_basket.urlified_name,
                 :controller_name_for_zoom_class => zoom_class_controller(zoom_class),
                 :source_controller_singular => zoom_class_controller(item.class.name).singularize,
                 :source_item => item }.merge(location)
    related_item_url = (location[:privacy_type] == 'private') ? basket_all_private_related_to_path(location) :
                                                                basket_all_related_to_path(location)
    link_to options[:link_text], related_item_url, { :class => 'small' }
  end

  # Creates the item list for display
  def related_items_display_of(items, options={})
    return '' if items.blank?
    unless options[:display_num].nil?
      display_num = options[:display_num]
      items = Array.new if display_num == 0
      items = items[0..(display_num - 1)] if display_num > 0
    end
    display_html = String.new
    display_html += options[:are_still_images] ? '<ul class="results-list images-list">' : '<ul>'
    items.each_with_index do |related_item,index|
      li_class = index == 0 ? 'first' : ''
      if related_item.is_a?(Hash)
        if related_item.is_a?(Hash) && !related_item[:thumbnail].blank?
          display_html += "<li class='#{li_class}'>#{related_image_link_for(related_item, options)}</li>"
        else
          display_html += "<li class='#{li_class}'>#{link_to(related_item[:title], related_item[:url])}</li>"
        end
      elsif related_item.is_a?(StillImage)
        display_html += "<li class='#{li_class}'>#{related_image_link_for(related_item, options)}</li>"
      else
        display_html += "<li class='#{li_class}'>#{link_to_item(related_item)}</li>"
      end
    end
    if (options[:item] && options[:zoom_class] && options[:display_num] && options[:total_num]) &&
          (options[:total_num] > options[:display_num])
      display_html += "<li>"
      more_num = options[:total_num] - options[:display_num]
      display_html += link_to_related_items_of(options[:item], options[:zoom_class], { :link_text => "#{more_num.to_s} more like this &gt;&gt;" }, { :privacy_type => options[:privacy_type] })
      display_html += "</li>"
    end
    display_html += "</ul>"
    display_html
  end

  # Creates an image and wraps in within a link tag
  def related_image_link_for(still_image, options={})
    options = { :privacy_type => 'public' }.merge(options)
    if still_image.is_a?(StillImage)
      if !still_image.thumbnail_file.nil?
        thumb_src_value = still_image.already_at_blank_version? ? '/images/pending.jpg' :
                                                                  still_image.thumbnail_file.public_filename
        link_text = image_tag(thumb_src_value, { :size => still_image.thumbnail_file.image_size,
                                                 :alt => "#{still_image.title}. " })
      else
        link_text = 'only available as original'
      end
      link_location = { :urlified_name => still_image.basket.urlified_name,
                        :controller => 'images', :action => 'show', :id => still_image,
                        :private => (options[:privacy_type] == 'private') }
    else
      thumb_src_value = still_image[:thumbnail][:src]
      link_text = image_tag(thumb_src_value, { :width => still_image[:thumbnail][:width],
                                               :height => still_image[:thumbnail][:height],
                                               :alt => "#{still_image[:title]}. " })
      link_location = still_image[:url]
    end
    link_to(link_text, link_location)
  end

  def link_to_related_item_function(options={})
    options = { :link_text => "#{options[:function].capitalize} an Existing Related Item" }.merge(options)
    link_text = options.delete(:link_text)
    disabled = false
    disabled = true if options[:function] == 'remove' && @total_item_counts < 1
    if options[:function] == 'restore'
      restore_count = ContentItemRelation::Deleted.count(:conditions => { :topic_id => options[:relate_to_topic] })
      disabled = true if restore_count < 1
      link_text += " (#{restore_count})"
    end
    link = disabled ? link_text : link_to(link_text, { :controller => 'search', :action => 'find_related' }.merge(options),
                                                     { :popup => ['links', 'height=500,width=500,scrollbars=yes,top=100,left=100,resizable=yes'] })
    content_tag('li', link)
  end

  def link_to_add_set_of_related_items(options={})
    options = { :link_text => "Import Set of Related Items" }.merge(options)
    link_text = options.delete(:link_text)
    link = link_to(link_text, { :controller => 'importers',
                                :action => 'new_related_set_from_archive_file',
                                :relate_to_topic => options[:relate_to_topic] })
    content_tag('li', link)
  end

  #
  # END RELATED ITEM HELPERS
  #


  # tag related helpers
  def link_to_tagged(tag, zoom_class = nil, basket = @site_basket)
    zoom_class = zoom_class || tag[:zoom_class]
    link_to h(tag[:name]),
            { :controller => 'search',
              :action => 'all',
              :tag => tag[:id],
              :trailing_slash => true,
              :controller_name_for_zoom_class => zoom_class_controller(zoom_class),
              :urlified_name => basket.urlified_name,
              :privacy_type => get_acceptable_privacy_type_for(nil, nil, "private") },
            :class => tag[:css_class]
  end
  alias :link_to_tagged_in_basket :link_to_tagged

  def tag_cloud(tags, classes)
    logger.info("using this")
    max, min = 0, 0
    tags.each { |t|
      t_count = t[:total_taggings_count].to_i
      max = t_count if t_count > max
      min = t_count if t_count < min
    }

    divisor = ((max - min) / classes.size) + 1

    tags.each { |t|
      t_count = t[:total_taggings_count].to_i
      yield t[:id], t[:name], classes[(t_count - min) / divisor]
    }
  end

  def tags_for(item)
    html_string = String.new

    return html_string if item.raw_tag_list.nil?

    raw_tag_array = Array.new
    # Get the raw tag list, split, squish (removed whitespace), and add each to raw_tag_array
    # Make sure we skip if the array already has that tag name (remove any duplicates that occur)
    item.raw_tag_list.split(',').each do |raw_tag|
      next if raw_tag_array.include?(raw_tag.squish)
      raw_tag_array << raw_tag.squish
    end

    # grab all the tag objects
    tags_out_of_order = Tag.find_all_by_name(raw_tag_array)
    if tags_out_of_order.size > 0
      tags = Array.new
      # resort them to match raw_tag_list order
      raw_tag_array.each do |tag_name|
        tag = tags_out_of_order.select { |tag| tag.name == tag_name }
        tags << tag
      end
      # at this point, we have an array, with arrays of object  [[tag], [tag], [tag]]
      # use compact to remove any nil objects, and flatten to convert it to [tag, tag, tag]
      tags = tags.compact.flatten

      html_string = "<p>Tags: "
      tags.each_with_index do |tag,index|
        html_string += link_to_tagged(tag, item.class.name)
        html_string += ", " unless tags.size == (index + 1)
      end
      html_string += "</p>"
    end

    html_string
  end

  def tags_input_field(form,label_for)
    "<div class=\"form-element\"><label for=\"#{label_for}\">Tags (separated by commas):</label>
                #{form.text_field :tag_list, :tabindex => '1'}</div>"
  end

  # if extended_field is passed in, use that to limit choices
  # else if @all_choices is true, we provide them all
  def limit_search_to_choice_control
    options_array = Array.new

    if @extended_field
      options_array = @extended_field.choices.find_top_level.inject([]) do |memo, choice|
        memo + option_for_choice_control(choice, :level => 0)
      end
    elsif @all_choices
      options_array = Choice.find_top_level.reject { |c| c.extended_fields.empty? }.inject([]) do |memo, choice|
        memo + option_for_choice_control(choice, :level => 0)
      end
    else
      return
    end

    html_options_for_select = ([['', '']] + options_array).map do |k, v|
      attrs = { :value => v }
      attrs.merge!(:selected => "selected") if params[:limit_to_choice] == v
      content_tag("option", k, attrs)
    end.join

    # Don't print out the SELECT tag unless there are choices available.
    options_array.flatten.empty? ? "" : select_tag("limit_to_choice", html_options_for_select)
  end

  def option_for_choice_control(choice, options = {})
    level = options[:level] || 0

    array = [[("&nbsp;&nbsp;"*level) + choice.label, choice.value]]
    choice.children.reject { |c| c.extended_fields.empty? }.inject(array) { |a, c| a + option_for_choice_control(c, :level => level + 1) }
  end

  #---- related to extended_fields for either topic_types or content_types
  def display_xml_attributes(item)
    raq = " &raquo; "
    html = []

    mappings = item.is_a?(Topic) ? item.all_field_mappings : \
      ContentType.find_by_class_name(item.class.name).content_type_to_field_mappings

    content = item.extended_content_pairs

    mappings.each do |mapping|
      field = mapping.extended_field
      # value = content[qualified_name_for_field(field)]
      field_name = field.multiple? ? qualified_name_for_field(field) + "_multiple" : qualified_name_for_field(field)

      value = content.select { |pair| pair[0] == field_name }.first.last rescue nil
      next if value.to_s.blank?

      value = formatted_extended_content_value(field, field_name, value, item)

      if field.ftype == 'map' || field.ftype == 'map_address'
        next if value.blank?
        td = content_tag("td", "#{field.label}:<br />#{value}", :class => "detail-extended-field-label", :colspan => 2)
      else
        td = content_tag("td", "#{field.label}:", :class => "detail-extended-field-label") +
             content_tag("td", value)
      end

      html << content_tag("tr", td)
    end

    unless html.empty?
      content_tag("table", content_tag("tbody", html.join), :class => "detail-extended-field-table", :summary => "Extended details")
    end

  end

  def formatted_extended_content_value(field, field_name, value, item)
    # handle if the field is multiple
    values = Array.new
    if field.multiple?
      values = value
    else
      values << value
    end

    # create an array of the result from processing each value
    # that way, if we need to, we can join on a bit of html code
    # or do "to_sentence" on the array
    output_array = Array.new

    values.each do |value_input|
      value_output = \
      if field.ftype == 'map'
        extended_field_map_editor(field_name, value_input, field, { :style => 'width:220px;' }, { :style => 'width:220px;' }, false, true, false)
      elsif field.ftype == 'map_address'
        extended_field_map_editor(field_name, value_input, field, { :style => 'width:220px;' }, { :style => 'width:220px;' }, false, true, true)
      else
        formatted_value_from_xml(value_input, field, item)
      end

      value_output = value_output.to_s

      # we prepend base_url to the value here
      # for the extended_field if it is set
      # but only if it hasn't been done previously in other formatting
      base_url = field.base_url
      unless base_url.blank? || %w(map map_address choice autocomplete).include?(field.ftype)
        value_output = link_to(value_output, base_url + value_output)
      end

      output_array << value_output
    end

    if output_array.size > 1
      unless %w(map map_address).include?(field.ftype)
        output_array.to_sentence
      else
        # TODO: look into how best to present multiple maps
        # they may not need any extra formatting
        output_array.join('<br\>')
      end
    else
      output_array.first
    end
  end

  def formatted_value_from_xml(value, ef = nil, item = nil)
    if ef && %w(autocomplete choice).member?(ef.ftype)
      base_url = ef.base_url

      # If the extended field type is a choice, then link the value to the search page for the EF.
      url_hash = {
        :controller_name_for_zoom_class => item.nil? ? 'topics' : zoom_class_controller(item.class.name),
        :controller => 'search',
        :extended_field => ef.label_for_params
      }

      if item.respond_to?(:private?) && item.private?
        method = 'basket_all_private_of_category_url'
        url_hash.merge!(:privacy_type => 'private')
      else
        method = 'basket_all_of_category_url'
      end

      # make the hash nested in an array so the map command does the right thing
      if value.is_a?(Hash) && value['label']
        value = [value]
      end

      value.map do |v|

        # use passed label if present
        # otherwise value is label
        l = v
        if v.is_a?(Hash) && v['label']
          l = v['label']
          v = v['value']
        end

        # the extended field's base_url takes precedence over
        # normal behavior creating a link to results
        # limited to choice for an extended field (a.k.a category_url in method names)
        unless base_url.blank?
          link_to(l, base_url + v)
        else
          link_to(l, send(method, url_hash.merge(:limit_to_choice => v)))
        end
      end.join(" &raquo; ")

    else

      value = value.first if value.is_a?(Array)

      label = value
      # use passed label if present
      # otherwise we use value as label
      if value.is_a?(Hash) && value['label']
        label = value['label']
        value = value['value']
      end

      case value
      when /^(.+)\((.+)\)$/
        # something (url)
        link_to($1, $2)
      when /^\w+:\/\/[^ ]+/
        # this is a url protocal of some sort, make link
        link_to(label, value)
      when /^\w+[^ ]*\@\w+\.\w/
        mail_to(label, value, :encode => "hex")
      else
        sanitize(value)
      end
    end
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
        comment_string = "<div class=\"comment-wrapper\">"
        comment_string += "<div class=\"comment-wrapper-header-wrapper\"><div class=\"comment-wrapper-header\"></div></div>"
        comment_string += "<div class=\"comment-content\">"
        comment_string += "#{comment.description}\n" unless comment.description.blank?
        tags_for_comment = tags_for(comment)
        comment_string += "#{tags_for_comment}\n" unless tags_for_comment.blank?
        comment_string += pending_review(comment) + "\n"
        comment_string += "<div class=\"comment-tools\">\n"
        comment_string += flagging_links_for(comment,true,'comments')
        if logged_in? and @at_least_a_moderator
          comment_string += "<ul>"
          comment_string += "<li class='first'>" + link_to("Edit",
                                             :controller => 'comments',
                                             :action => :edit,
                                             :id => comment) + "</li>\n"
          comment_string += "<li>" + link_to("History",
                                             :controller => 'comments',
                                             :action => :history,
                                             :id => comment) + "</li>\n"
          comment_string += "<li>" + link_to("Delete",
                                             {:action => :destroy,
                                               :controller => 'comments',
                                               :id => comment,
                                               :authenticity_token => form_authenticity_token},
                                             :method => :post,
                                             :confirm => 'Are you sure?') + "</li>\n"
          comment_string += "</ul>\n"
        end
        comment_string += "</div>" # comment-tools
        comment_string += "</div>" # comment-content
        comment_string += "<div class=\"comment-wrapper-footer-wrapper\"><div class=\"comment-wrapper-footer\"></div></div>"
        comment_string += "</div>" # comment-wrapper

        html_string += '<div class="comment-outer-wrapper">'
        html_string += stylish_link_to_contributions_of(comment.creators.first, 'Comment',
                                                        :link_text => "<h3>|user_name_link|</h3><div class=\"stylish_user_contribution_link_extra\"><h3>&nbsp;said <a name=\"comment-#{comment.id}\">#{h(comment.title)}</a></h3></div>",
                                                        :additional_html => comment_string)
        html_string += '</div>' # comment-outer-wrapper
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

  def link_to_original_of(item, phrase='view', skip_warning=false)
    item_file_url = item.is_a?(StillImage) ? item.original_file.public_filename : item.public_filename
    if DOWNLOAD_WARNING.blank? || skip_warning
      link_to phrase, item_file_url
    else
      link_to phrase, item_file_url, :confirm => DOWNLOAD_WARNING
    end
  end

  # we use this in imports, too
  def topic_type_select_with_indent(object, method, collection, value_method, text_method, current_value, html_options=Hash.new, pre_options=Array.new)
    result = "<select name=\"#{object}[#{method}]\" id=\"#{object}_#{method}\""
    html_options.each do |key, value|
        result << ' ' + key.to_s + '="' + value.to_s + '"'
    end
    result << ">\n"
    result << options_for_select(pre_options) unless pre_options.blank?
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
  def show_privacy_controls?(basket = @current_basket)
    basket.show_privacy_controls_with_inheritance?
  end
  alias show_privacy_controls_for_basket? show_privacy_controls?

  def show_privacy_search_controls?
    if @current_basket == @site_basket
      # note that it has to be "== true" in combination with ||, or you will get unexpected results when show_privacy_controls is not nil and == false
      (@site_basket.show_privacy_controls == true or Basket.privacy_exists)
    else
      @current_basket.show_privacy_controls_with_inheritance?
    end
  end

  # Check whether to show privacy controls for an item
  def show_privacy_controls_for?(item, basket=nil)
    basket = (basket || item.basket)
    show_privacy_controls_for_basket?(basket) &&
      ( item.new_record? ||
        current_user_can_see_private_files_in_basket?(basket) ||
        @current_user == item.creator )
  end

  # Controls for search sorting on pages like basket list and basket members list
  def search_sorting_controls_for(sort_text, sort_type, main_sort_order=false, default_direction='asc', remote_link = false)
    # if searching, get the current sort direction else use the default order
    direction = (params[:order] == sort_type ? params[:direction] : nil) || default_direction

    # using the current sort direction, create the image we'll use display
    if direction == 'desc'
      direction_image = image_tag('arrow_down.gif', :alt => 'Descending. ', :class => 'sorting_control', :width => 16, :height => 7)
    else
      direction == 'asc' # if direction is something else, we set it right here
      direction_image = image_tag('arrow_up.gif', :alt => 'Ascending. ', :class => 'sorting_control', :width => 16, :height => 7)
    end

    # create the link based on sort type and direction (user provided or default)
    # keep existing parameters
    location_hash = Hash.new
    # this has keys in strings, rather than symbols
    request.query_parameters.each { |key, value| location_hash[key.to_sym] = value }
    location_hash.merge!({ :order => sort_type })
    location_hash.merge!({ :direction => direction}) if sort_type != 'random'

    # if sorting and the sort is for this sort type, or no sort made and this sort type is the main sort order
    if (params[:order] && params[:order] == sort_type && sort_type != 'random') || (!params[:order] && main_sort_order)
      # flip the current direction so clicking the link reverses direction
      location_hash.merge!({ :direction => sort_direction_after(direction) })
      link_to_text = "#{sort_text} #{direction_image}"
    else
      link_to_text = "#{sort_text}"
    end

    # create the link with text, current direction image (if needed), and pointing to opposite direction (if needed)
    if remote_link
      # create a remote to link
      link_to_remote link_to_text, { :url => location_hash,
                                     :before => "Element.show('data_spinner')",
                                     :complete => "Element.hide('data_spinner')" },
                                   :href => url_for(location_hash)
    else
      # create a plain link
      link_to link_to_text, location_hash
    end
  end

  # The method uses to flip the current direction, so we get the reverse of the current
  # Used in search_sorting_controls_for
  def sort_direction_after(current_direction)
    directions = { 'asc' => 'desc', 'desc' => 'asc' }
    directions[current_direction]
  end

  def privacy_image
    # not happy with this icon, just say private: for now
    # TODO: replace with better icon
    # image_tag 'privacy_icon.gif', :width => 16, :height => 15, :alt => "This item is private. ", :class => 'privacy_icon'
      "private: "
  end

  def privacy_image_for(item)
    if item.private?
      privacy_image
    end
  end

  def kete_time_ago_in_words(from_time)
    string = String.new
    if from_time < Time.now - 1.week
      string = "on " + from_time.to_s(:euro_date_time)
    else
      string = time_ago_in_words(from_time) + " ago"
    end
    string
  end

  # when embedded metadata is set up to be harvested, give an explanation that it is enabled.
  # oriented towards imports at this point, but maybe refined to be generally useful
  def embedded_enabled_message(start_html, end_html)
    html = String.new
    if ENABLE_EMBEDDED_SUPPORT
      html += start_html
      html+= "Embedded metadata will be harvested from the item's binary file to fill out any fields that match the site's settings."
      html += end_html
    end
    html
  end


  # if string ends with a period already, or a period and a space, don't add them
  # otherwise, add them
  # we also replace any ending punctuation with period for the purposes of alts
  # including multiple instances
  def altify(string)
    return string if string =~ /\. $/
    string = string.chomp(" ")
    string = string.sub(/\W+$/, ".")
    string += ". " if string =~ /[^\.]$/
    string += " " if string =~ /\.$/
    string
  end

  def browse_by_category_columns
    # Do we have a categories extended field to work from?
    categories = ExtendedField.find_by_label('categories')
    # If not, return blank so nothing is displayed
    return '' if categories.nil? || !categories.is_a_choice?

    # Get the current choice from params (limit_to_choice is special because it also controls search results)
    current_choice = Choice.find_by_value(params[:limit_to_choice])
    parent_choices = Array.new
    # Now we have the current choice, recursively go back until we reach the top level
    # (adding each parent to the end of the parent_choices array)
    unless current_choice.nil?
      parent_choices = [current_choice]
      still_child_element = true
      while still_child_element
        current_choice = current_choice.parent
        if current_choice.nil?
          still_child_element = false
        else
          parent_choices << current_choice unless current_choice.id == 1
        end
      end
    end
    # Finally, add the root category extended field to array
    parent_choices << categories

    html = String.new

    # For each level in the parent choices
    parent_choices.size.times do |time|
      # pop the first parent off the end of the parent_choices array
      current_choice = parent_choices.pop

      # Skip this choice if it doesn't have any choices
      next if current_choice.choices.size < 1

      html += "<div id='category_level_#{time}' class='category_list'>"
      html += "<ul>"
      # For every choice in the current choice, lets add a list item
      current_choice.choices.each do |choice|
        # if this choice exists in the parent_choices, then mark it as current parent/choice
        html += parent_choices.include?(choice) ? "<li class='current'>" : "<li>"
        html += link_to(choice.label,
                        basket_all_path(:urlified_name => params[:urlified_name],
                                        :controller_name_for_zoom_class => params[:controller_name_for_zoom_class],
                                        :limit_to_choice => choice.value),
                        :title => choice.value)
        html += "</li>"
      end
      html += '</ul>'
      html += '</div>'
    end

    html += "<div style='clear:both;'></div>"
    #html += javascript_tag("enableCategoryListUpdater('#{params[:controller_name_for_zoom_class]}');")

    html

  end

end
