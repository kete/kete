# Controls needed for Gravatar support throughout the site
require 'avatar/view/action_view_support'
require 'redcloth'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ExtendedFieldsHelpers

  include ExtendedContentHelpers

  include OaiDcHelpers

  include ZoomHelpers

  def stripped_title
    h(strip_tags(@title))
  end

  def title_with_context
    if @current_basket == @site_basket
      "#{stripped_title} - #{PRETTY_SITE_NAME}"
    else
      "#{stripped_title} - #{@current_basket.name} - #{PRETTY_SITE_NAME}"
    end
  end

  # Get the integer of any given image size
  def image_size_of(string)
    size = IMAGE_SIZES[string.to_sym].is_a?(String) ? \
             IMAGE_SIZES[string.to_sym].split('x').first : \
             IMAGE_SIZES[string.to_sym].first
    size.gsub(/(!|>|<)/, '').to_i
  end

  # Controls needed for Gravatar support throughout the site
  include Avatar::View::ActionViewSupport
  def avatar_for(user, options = {})
    # New installs use strings for the small_sq value, but we have to handle legacy settings containing arrays
    image_dimension = IMAGE_SIZES[:small_sq].is_a?(String) ? \
                        IMAGE_SIZES[:small_sq].gsub(/(!|>|<)/, '').split('x').first.to_i : \
                        IMAGE_SIZES[:small_sq].first
    default_options = { :width => image_dimension,
                        :height => image_dimension,
                        :alt => t('application_helper.avatar_for.users_avatar',
                                  :user_name => user.user_name) }
    options = default_options.merge(options)

    return nil if options[:return_portrait] && (!ENABLE_USER_PORTRAITS || user.avatar.nil?)

    if ENABLE_USER_PORTRAITS && user.avatar
      if options[:return_portrait]
        return user.avatar
      else
        return image_tag(user.avatar.thumbnail_file.public_filename, options)
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

  def short_summary_or_description_of(item)
    description_text = ((item.respond_to?(:short_summary) && !item.short_summary.blank?) ? item.short_summary : item.description) || String.new
    strip_tags(truncate(description_text, :length => 180, :omission => '...')).gsub("\"", "").squish
  end

  def page_description
    return DEFAULT_PAGE_DESCRIPTION if current_item.nil?
    description_text = short_summary_or_description_of(current_item)
    return DEFAULT_PAGE_DESCRIPTION if description_text.blank?
    description_text
  end

  def meta_tag(*args)
    tag(:meta, *args) + "\n"
  end

  def dc_metadata_for(item)
    metadata = String.new

    metadata += tag(:link, :rel => "schema.DCTERMS", :href => "http://purl.org/dc/terms/") + "\n"
    metadata += tag(:link, :rel => "schema.DC", :href => "http://purl.org/dc/elements/1.1/") + "\n"

    metadata += meta_tag(:name => 'DC.identifier', :content => url_for_dc_identifier(item), :scheme => "DCTERMS.URI")
    metadata += meta_tag(:name => 'DC.title', :content => h(item.title))

    # If someone requests the description, uncomment this, else for now, leave it
    # metadata += meta_tag(:name => 'DC.description', :content => short_summary_or_description_of(item))

    item.tags.each do |tag|
      metadata += meta_tag(:name => 'DC.subject', :content => h(tag))
    end

    metadata += meta_tag(:name => 'DC.creator', :content => h(item.creator.user_name))
    metadata += meta_tag(:name => 'DC.contributor', :content => h(item.contributors.last.user_name) + ", et al") if item.contributors.size > 1
    metadata += meta_tag(:name => 'DC.publisher', :content => h(PRETTY_SITE_NAME))
    metadata += meta_tag(:name => 'DC.type', :content => 'Text')
    metadata += meta_tag(:name => 'DC.rights', :content => h(item.license.name + " (" + item.license.url + ")")) if item.license

    # A bit misleading as we have images and possible files attached to this item
    # metadata += meta_tag(:name => 'DC.format', :content => 'text/html')

    # Don't support content translations yet, but when we do, uncomment this
    # metadata += meta_tag(:name => 'DC.language', :content => I18n.locale, :scheme => "DCTERMS.RFC1766")

    # We don't have a published date at the moment
    # metadata += meta_tag(:name => 'DC.date', :content => item.created_at.to_date, :scheme => "IS08601")

    metadata
  end

  def opensearch_descriptions
    tag(:link, :rel => "search",
               :type => "application/opensearchdescription+xml",
               :href => "#{SITE_URL}opensearchdescription.xml",
               :title => "#{PRETTY_SITE_NAME} Web Search")
  end

  def open_search_metadata
    # only continue if we have results, which aren't available on a 404 or 500 page
    return unless @result_sets && @current_class && @result_sets[@current_class]

    meta_tag(:name => "totalResults", :content => @result_sets[@current_class].size) +
    meta_tag(:name => "startIndex", :content => ((@current_page - 1) * @number_per_page)) +
    meta_tag(:name => "itemsPerPage", :content => @number_per_page)
  end

  def initialize_gmap_headers?
    @map.present? &&
      (params[:controller] == 'search' &&
      ['all', 'for'].include?(params[:action]) &&
      (!params[:view_as].blank? && params[:view_as] == 'map'))
  end

  def header_links_to_baskets
    baskets_limit = LIST_BASKETS_NUMBER
    return unless baskets_limit > 0

    html = '<ul id="basket-list" class="nav-list">'

    except_certain_baskets = @standard_baskets
    except_certain_baskets += [@current_basket] if @current_basket != @site_basket

    except_certain_baskets_args = { :conditions => ["id not in (?) AND status = 'approved'", except_certain_baskets] }

    total_baskets_count = Basket.count(except_certain_baskets_args)

    except_certain_baskets_args[:limit] = baskets_limit

    basket_count = 0
    Basket.find(:all, except_certain_baskets_args).each do |basket|
      basket_count += 1
      html += li_with_correct_class(basket_count) + link_to_index_for(basket) + '</li>'
    end

    if baskets_limit < total_baskets_count
      html += '<li>' + link_to_unless_current(t('application_helper.header_links_to_baskets.more_baskets'),
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
    if @current_basket != @site_basket
      html += t('application_helper.header_link_to_current_basket.separator')
      html += link_to_index_for(@current_basket, { :class => 'basket', :tabindex => '2' })
    end
  end

  def default_search_terms
    search_location_name = PRETTY_SITE_NAME
    search_text_key = 'search_value'

    if SEARCH_SELECT_CURRENT_BASKET && @current_basket != @site_basket
      search_location_name = @current_basket.name
      search_text_key = 'search_value_within'
    end

    search_text_key = "new_#{search_text_key}" if params[:controller] == 'search'
    t("layouts.application.#{search_text_key}", :search_location_name => search_location_name)
  end

  def default_search_terms_for_js
    escape_javascript(default_search_terms)
  end

  def add_search_icon_and_default_text_to_search_box(id, trigger_id)
    search_dropdown_link = link_to(image_tag('search.png', :width => 20, :height => 13), '#',
                                   :onclick => "$('#{id}').toggle();
                                                if($('search_terms').value == '#{default_search_terms_for_js}') {
                                                  $('search_terms').value = '';
                                                }", :title => t('application_helper.add_search_icon_and_default_text_to_search_box.more_search_options'))
    javascript_tag("$('#{trigger_id}').insert('#{escape_javascript(search_dropdown_link)}');") +
    javascript_tag("addDefaultValueToSearchTerms('#{default_search_terms_for_js}');")
  end

  # Clear any values that shouldn't be there when we make a new search or refine a search
  def overwritten_search_params
    {
      # set basic values for our search
      :urlified_name => @current_basket.urlified_name,
      :controller => 'search',
      :action => 'terms_to_page_url_redirect',

      # clear these from the params so the form fields take effect instead
      :search_terms => nil,
      :date_since => nil,
      :date_until => nil,
      :topic_type => nil,
      :privacy_type => nil,
      :sort_type => nil,
      :sort_direction => nil,
      :limit_to_choice => nil,
      :extended_field => nil,

      # no sense in keeping page number, new results could be much less causing 404's
      :page => nil
    }
  end

  def search_link_to_searched_basket
    html = String.new
    html += ' ' + link_to_index_for(@current_basket, { :class => 'basket' }) if @current_basket != @site_basket
  end

  def link_to_index_for(basket, options = { })
    link_to basket.name, basket_index_url({ :urlified_name => basket.urlified_name }), options
  end

  def header_browse_links
    html = '<li id="header_browse">'

    pre_text = String.new
    site_link_text = String.new
    current_basket_html = String.new
    default_controller = zoom_class_controller(DEFAULT_SEARCH_CLASS)
    if @current_basket != @site_basket
      pre_text = "#{t('application_helper.header_browse_links.browse')}: "
      site_link_text = @site_basket.name
      privacy_type = (@current_basket.private_default_with_inheritance? && permitted_to_view_private_items?) ? 'private' : nil
      current_basket_html = " #{t('application_helper.header_browse_links.browse_or')} "
      current_basket_html += link_to_unless_current( @current_basket.name,
                                                     { :controller => 'search',
                                                       :action => 'all',
                                                       :urlified_name => @current_basket.urlified_name,
                                                       :controller_name_for_zoom_class => default_controller,
                                                       :trailing_slash => true,
                                                       :privacy_type => privacy_type,
                                                       :view_as => @current_basket.browse_type_with_inheritance },
                                                     { :tabindex => '2' } )
    else
      site_link_text = t('application_helper.header_browse_links.browse')
    end

    html += pre_text + link_to_unless_current( site_link_text,
                                               {:controller => 'search',
                                               :action => 'all',
                                               :urlified_name => @site_basket.urlified_name,
                                               :controller_name_for_zoom_class => default_controller,
                                               :trailing_slash => true,
                                               :view_as => @site_basket.browse_type_with_inheritance }, {:tabindex => '2'} ) + current_basket_html + '</li>'
  end

  def header_add_links(options={})
    return unless current_user_can_see_add_links?
    options = { :link_text => t('application_helper.header_add_links.add_item') }.merge(options)
    link_text = options.delete(:link_text)
    li_class = options.delete(:class) || ''
    html = "<li id='header_add_item' class='#{li_class}'>"
    html += link_to_unless_current(link_text,
                                   { :controller => 'baskets',
                                     :action => 'choose_type',
                                     :urlified_name => @current_basket.urlified_name }.merge(options),
                                   { :tabindex => '2' })
    html += '</li>'
  end

  def users_baskets_list(user=current_user, options ={})
    # if the user is the current user, use the basket_access_hash instead of fetching them again
    basket_permissions = (user == current_user) ? @basket_access_hash : user.basket_permissions

    row1 = 'user_basket_list_row1'
    row2 = 'user_basket_list_row2'
    css_class = row1

    if user == current_user || @site_admin
      Basket.find_all_by_status_and_creator_id('requested', user, :select => 'urlified_name').each do |basket|
        if basket_permissions[basket.urlified_name.to_sym].blank?
          basket_permissions[basket.urlified_name.to_sym] = Hash.new
        end
      end
    end

    html = String.new
    basket_permissions.each do |basket_name, role|
      basket = Basket.find_by_urlified_name(basket_name.to_s)
      next unless user == current_user || current_user_can_see_memberlist_for?(basket)
      pending = (basket.status == 'requested') ? t('application_helper.users_baskets_list.basket_pending') : ''
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
      basket_text = t('application_helper.header_add_basket_link.request_basket')
    else
      basket_text = t('application_helper.header_add_basket_link.add_basket')
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
          html += content_tag("li", link_to(t('application_helper.render_baskets_as_menu.more'),
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
      return link_to(t('application_helper.link_to_last_stored_location.back_to_kete_home'), '/')
    else
      return link_to(t('application_helper.link_to_last_stored_location.back_to_stored_location',
                       :stored_location => session[:return_to_title]),
                     session[:return_to])
    end
  end

  def link_to_members_of(basket, options={})
    options = { :viewable_text => t('application_helper.link_to_members_of.members_link_text'),
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

    options = { :join_text => t('application_helper.link_to_membership_request_of.join'),
                :request_text => t('application_helper.link_to_membership_request_of.request'),
                :closed_text => "",
                :as_list_element => true,
                :plus_divider => "",
                :pending_text => t('application_helper.link_to_membership_request_of.pending'),
                :rejected_text => t('application_helper.link_to_membership_request_of.rejected'),
                :current_role => t('application_helper.link_to_membership_request_of.current_role'),
                :leave_text => t('application_helper.link_to_membership_request_of.leave') }.merge(options)

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
        html += link_to(options[:current_role].gsub('|role|', role),
                        { :urlified_name => @site_basket.urlified_name,
                          :controller => 'account',
                          :action => 'baskets' }) if show_roles
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
    link_text = t('application_helper.link_to_basket_contact_for.contact')
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
      html += link_to(t('application_helper.link_to_cancel.cancel'), :action => 'list', :tabindex => '1')
    else
      html += link_to(t('application_helper.link_to_cancel.cancel'), url_for(session[:return_to]), :tabindex => '1')
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

  def link_to_contributions_of(user, zoom_class = 'Topic', options = {})
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

    phrase += ' ' + content_tag('span', zoom_class_humanize(item_class), :class => 'current_zoom_class')

    if @current_basket != @site_basket
      phrase += t('application_helper.link_to_add_item.in_basket',
                  :basket_name => @current_basket.name)
    end

    return link_to(phrase, {:controller => zoom_class_controller(item_class), :action => :new}, :tabindex => '1')
  end

  #
  # START RELATED ITEM HELPERS
  #

  def related_items_positions
    [
      [t('application_helper.related_items_positions.below'), 'below'],
      [t('application_helper.related_items_positions.inset'), 'inset'],
      [t('application_helper.related_items_positions.sidebar'), 'sidebar']
    ]
  end

  def class_suffix_from(position)
    case position
    when 'inset'
      "-white"
    when 'below'
      "-blue"
    else
      "" # grey sidebar
    end
  end

  def class_and_styles_from(position = nil, count = nil)
    class_names, styles = Array.new, Array.new

    class_names << position if position
    styles << "width: #{(image_size_of(IMAGE_SLIDESHOW_SIZE) + 30)}px;" if position && position == 'inset'

    # Used to hide the empty, thin related items box on inset or sidebar display when no related items
    # are present. Only apply this if no items are present and only if we are on non-topic controller
    # (topic page related items have create/link etc controls that we don't want to hide)
    class_names << "no-items" if count && count == 0 && params[:controller] != 'topics'

    " class='#{class_names.join(' ')}' style='#{styles.join}'"
  end

  def related_items_count_for_current_item
    @related_items_count_for_current_item ||= begin
      conditions = "(content_item_relations.related_item_id = :cache_id AND content_item_relations.related_item_type = '#{zoom_class_from_controller(params[:controller])}')"
      conditions += " OR (content_item_relations.topic_id = :cache_id)" if params[:controller] == 'topics'
      ContentItemRelation.count(:conditions => [conditions, { :cache_id => @cache_id }])
    end
  end

  # Create two methods for fetching public and private related items
  # Both are identical except for method names, so use module_eval
  # so we don't have to repeat ourselves.
  %w{ public_related_items_for private_related_items_for }.each do |method_name|
    module_eval <<-EOT, __FILE__, __LINE__ + 1
      def #{method_name}(item, options={})
        options = { :start_record => nil, :end_record => nil,
                    :dont_parse_results => nil, :item_classes => nil }.merge(options)
        items = Hash.new
        counts = Hash.new if options[:with_counts]

        options[:item_classes] ||= ITEM_CLASSES
        options[:item_classes].each do |item_class|
          results = find_#{method_name}(item, item_class, options)
          items[item_class] = results[:results]
          counts[item_class] = results[:total] if options[:with_counts]
        end

        options[:with_counts] ? [items, counts] : items
      end
    EOT
  end

  # Gets the total amount of related items for a specific zoom class
  def related_items_count_of(zoom_class)
    (@public_item_counts[zoom_class] + @private_item_counts[zoom_class])
  end

  # Returns true if only public items exist, else false of private ones are present
  def only_public_related_items_of?(zoom_class)
    (@public_item_counts[zoom_class] > 0 && @private_item_counts[zoom_class] < 1)
  end

  # Link to the related items of a certain item
  def link_to_related_items_of(item, zoom_class, options={}, location={})
    options = { :link_text => t('application_helper.link_to_related_items_of.link_text',
                                :item_title => item.title) }.merge(options)
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
      display_html += "<li class='more'>"
      more_num = options[:total_num] - options[:display_num]
      display_html += link_to_related_items_of(options[:item], options[:zoom_class], { :link_text => "#{more_num.to_s} more like this &gt;&gt;" }, { :privacy_type => options[:privacy_type] })
      display_html += "</li>"
    end
    display_html += "</ul>"
    display_html
  end

  # Creates an image and wraps in within a link tag
  def related_image_link_for(still_image, options={}, link_options={})
    return '' if still_image.blank?
    options = { :privacy_type => 'public' }.merge(options)
    if still_image.is_a?(StillImage)
      if !still_image.thumbnail_file.nil?
        thumb_src_value = still_image.already_at_blank_version? ? '/images/pending.jpg' :
                                                                  still_image.thumbnail_file.public_filename
        link_text = image_tag(thumb_src_value, { :size => still_image.thumbnail_file.image_size,
                                                 :alt => "#{still_image.title}. " })
      else
        link_text = t('application_helper.related_image_link_for.only_original')
      end
      if link_options.is_a?(String)
        link_location = link_options
      else
        link_location = { :urlified_name => still_image.basket.urlified_name,
                          :controller => 'images', :action => 'show', :id => still_image,
                          :private => (options[:privacy_type] == 'private') }.merge(link_options)
      end
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
    options = { :link_text => t('application_helper.link_to_related_item_function.link_text',
                                :function => options[:function].capitalize) }.merge(options)
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
    options = { :link_text => t('application_helper.link_to_add_set_of_related_items.link_text') }.merge(options)
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
    tag_for_url = !tag[:to_param].blank? ? tag[:to_param] : tag.to_param
    link_to h(tag[:name]),
            { :controller => 'search',
              :action => 'all',
              :tag => tag_for_url,
              :trailing_slash => true,
              :controller_name_for_zoom_class => zoom_class_controller(zoom_class),
              :urlified_name => basket.urlified_name,
              :privacy_type => get_acceptable_privacy_type_for(nil, nil, "private") },
            :class => tag[:css_class]
  end
  alias :link_to_tagged_in_basket :link_to_tagged

  def tag_cloud(tags, classes)
    max, min = 0, 0
    tags.each { |t|
      t_count = t[:total_taggings_count].to_i
      max = t_count if t_count > max
      min = t_count if t_count < min
    }

    divisor = ((max - min) / classes.size) + 1

    tags.each { |t|
      t_count = t[:total_taggings_count].to_i
      yield t[:id], t[:name], classes[(t_count - min) / divisor], t[:to_param]
    }
  end

  def tags_for(item)
    html_string = String.new

    return html_string if item.tags.blank?

    html_string = "<p>#{t('application_helper.tags_for.tags')} "
    item_tags = item.tags
    logger.debug("what are item_tags: " + item_tags.inspect)
    item_tags.each_with_index do |tag,index|
      html_string += link_to_tagged(tag, item.class.name)
      html_string += ", " unless item_tags.size == (index + 1)
    end
    html_string += "</p>"

    html_string
  end

  def tags_input_field(form,label_for)
    "<div class=\"form-element\"><label for=\"#{label_for}\">#{t('application_helper.tags_input_field.tags')}</label>
                #{form.text_field :tag_list, :tabindex => '1'}</div>"
  end

  #
  # Start Search Control Dropdown Helpers
  #

  def display_search_field_for?(field_type, setting_value)
    ['all', field_type].include?(setting_value)
  end

  def topic_type_useful_here?(type)
    display_search_field_for?(type, DISPLAY_ITEM_TYPE_FIELD) || params[:controller_name_for_zoom_class] == 'topics'
  end

  def toggle_topic_types_field_js_helper_for(parent_id)
    javascript_tag "
    if ($$('##{parent_id} #controller_name_for_zoom_class').first() && $$('##{parent_id} #topic_type').first().up('tr')) {
      if ($$('##{parent_id} #controller_name_for_zoom_class').first().value != 'topics') {
        $$('##{parent_id} #topic_type').first().up('tr').hide();
      }
      $$('##{parent_id} #controller_name_for_zoom_class').first().observe('change', function(event) {
        if (this.value == 'topics') {
          $$('##{parent_id} #topic_type').first().up('tr').show();
        } else {
          $$('##{parent_id} #topic_type').first().up('tr').hide();
        }
      });
    }
    "
  end

  def current_sort_type
    if params[:sort_type].present?
      params[:sort_type]
    elsif @current_basket.settings[:sort_order_default].present?
      @current_basket.settings[:sort_order_default]
    end
  end

  def current_sort_direction
    if params[:sort_direction].present?
      params[:sort_direction]
    elsif @current_basket.settings[:sort_direction_reversed_default].present?
      @current_basket.settings[:sort_direction_reversed_default]
    end
  end

  def toggle_relevance_field_js_helper_for(parent_id)
    js = "
    function #{parent_id}_any_fields_provided() {
      if ($$('##{parent_id} #search_terms').first() && $$('##{parent_id} #search_terms').first().value != '') { return true; }
      if ($$('##{parent_id} #date_since').first() && $$('##{parent_id} #date_since').first().value != '') { return true; }
      if ($$('##{parent_id} #date_until').first() && $$('##{parent_id} #date_until').first().value != '') { return true; }
      return false;
    }
    function #{parent_id}_reset_relevance(force) {
      if (!force && (#{parent_id}_any_fields_provided() || !$$('##{parent_id} #sort_type').first())) { return; }
      if ($$('##{parent_id} #sort_type').first().down('.title')) { $$('##{parent_id} #sort_type').first().down('.title').selected = true; }
      if ($$('##{parent_id} #sort_direction_field').first()) { $$('##{parent_id} #sort_direction_field').first().show(); }
      if ($$('##{parent_id} #sort_type').first().down('.none')) { $$('##{parent_id} #sort_type').first().down('.none').hide(); }
    }
    function #{parent_id}_show_relevance(force) {
      if (!force && (!#{parent_id}_any_fields_provided() || !$$('##{parent_id} #sort_type').first())) { return; }
      if ($$('##{parent_id} #sort_type').first().down('.none')) { $$('##{parent_id} #sort_type').first().down('.none').show(); }
    }
    #{parent_id}_reset_relevance();
    "
    %w{ search_terms date_since date_until }.each do |field|
      js += "
      if ($$('##{parent_id} ##{field}').first()) { $$('##{parent_id} ##{field}').first().observe('change', function(event) {
        if (this.value == '') { #{parent_id}_reset_relevance(); } else { #{parent_id}_show_relevance(); }
      }); }
      "
    end
    javascript_tag(js)
  end

  def toggle_in_reverse_field_js_helper_for(parent_id)
    javascript_tag "
    if ($$('##{parent_id} #sort_type').first() && $$('##{parent_id} #sort_direction_field').first()) {
      if ($$('##{parent_id} #sort_type').first().value == 'none') {
        $$('##{parent_id} #sort_direction_field').first().hide();
      }
      $$('##{parent_id} #sort_type').first().observe('change', function(event) {
        if (this.value == 'none') {
          $$('##{parent_id} #sort_direction_field').first().hide();
        } else {
          $$('##{parent_id} #sort_direction_field').first().show();
        }
      });
    }
    "
  end

  def basket_option_for(basket, options = {})
    content_tag(:option, (options[:label] || basket.name), {
      :value => (options[:value] || basket.urlified_name),
      :class => ('not_member' unless @basket_access_hash.key?(basket.urlified_name.to_sym)),
      :selected => ('selected' if options[:selected] && basket.urlified_name.to_sym == options[:selected].to_sym)
    })
  end

  def adjust_target_basket_options_for_privacy(privacy)
    return unless privacy
    html = javascript_tag("
      function show_all_target_baskets() {
        $$('#target_basket option').each(function(element) { element.show(); });
      }

      function hide_all_non_member_target_baskets() {
        $$('#target_basket option.not_member').each(function(element) { element.hide(); });
        var current_selection = $('target_basket').options[$('target_basket').selectedIndex];
        // TODO: take this IE specific code out when it is no longer needed
        var agent = navigator.userAgent.toLowerCase ();
        if (agent.search ('msie') > -1) {
          if (!current_selection.style.visibility == 'hidden') { $('target_basket').options[0].selected = true; }
        } else {
          if (!current_selection.visible()) { $('target_basket').options[0].selected = true; }
        }
      }

      $('privacy_type_public').observe('click', function() { show_all_target_baskets(); });
      $('privacy_type_private').observe('click', function() { hide_all_non_member_target_baskets(); });
    ")
    html += javascript_tag("hide_all_non_member_target_baskets();") if privacy.to_sym == :private
    html
  end

  #
  # End Search Control Dropdown Helpers
  #

  # if extended_field is passed in, use that to limit choices
  # else if @all_choices is true, we provide them all
  def limit_search_to_choice_control(clear_values = false)
    options_array = Array.new

    if @extended_field
      options_array = @extended_field.choices.find_top_level.inject([]) do |memo, choice|
        memo + option_for_choice_control(choice, :level => 0)
      end
    elsif categories_field
      options_array = categories_field.choices.find_top_level.reject { |c| c.extended_fields.empty? }.inject([]) do |memo, choice|
        memo + option_for_choice_control(choice, :level => 0)
      end
    else
      return
    end

    html_options_for_select = ([['', '']] + options_array).map do |k, v|
      attrs = { :value => v }
      attrs.merge!(:selected => "selected") if !clear_values && @limit_to_choice && @limit_to_choice.value == v
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
  def display_xml_attributes(item, options = {})
    raq = " &raquo; "
    html = []

    mappings = item.is_a?(Topic) ? item.all_field_mappings : \
      ContentType.find_by_class_name(item.class.name).content_type_to_field_mappings

    content = item.extended_content_pairs

    mappings.each do |mapping|
      unless options[:embedded_only].nil?
        if options[:embedded_only]
          next unless mapping.embedded?
        else
          next if mapping.embedded?
        end
      end

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
        :urlified_name => @site_basket.urlified_name,
        :controller_name_for_zoom_class => item.nil? ? 'topics' : zoom_class_controller(item.class.name),
        :controller => 'search',
        :extended_field => ef
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

        choice = Choice.from_id_or_value(v)

        # the extended field's base_url takes precedence over
        # normal behavior creating a link to results
        # limited to choice for an extended field (a.k.a category_url in method names)
        unless base_url.blank?
          link_to(l, base_url + choice.to_param)
        else
          if ef && ef.dont_link_choice_values?
            l
          else
            link_to(l, send(method, url_hash.merge(:limit_to_choice => choice.to_param)))
          end
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

      # append c. for circa for fields that are circa
      if value.is_a?(Hash) && value['circa']
        label = (value['circa'] == '1') ? "c.#{value['value']}" : value['value']
        value = label
      end

      # textboxes are different than other content types because they can have multiple links
      # or emails or such in the some field and we want to catch all those.
      if ef.ftype == 'textarea'
        value = sanitize(value)

        # format the value to html with RedCloth for things like line breaks
        # start by replacing carriage returns with newlines
        # gotcha: if you have a \r\n or \n\r, you need to convert both to a
        # single new line before converting all remaining \r to \n (else
        # you get double lines where there should only be a single)
        value = value.gsub(/(\r\n|\n\r|\r)/, "\n")
        value = RedCloth.new(value).to_html

        url_regex = '(\w+:\/\/[^ |<]+)'
        email_regex = '([\w._%+-]+@[\w.-]+\.[\w]{2,4})'

        value.gsub!(/(^|\s)#{url_regex}/) { $1 + link_to($2.strip, $2.strip) }
        value.gsub!(/(^|\s)#{email_regex}/) { $1 + mail_to($2.strip, $2.strip, :encode => "hex") }

        value
      else

        case value
        when /^(.+)\((\w{3,9}:\/\/.+)\)$/
          # something (url)
          link_to($1.strip, $2)
        when /^\w+:\/\/[^ ]+/
          # this is a url protocal of some sort, make link
          link_to(label, value)
        when /^[\w._%+-]+@[\w.-]+\.[\w]{2,4}$/
          mail_to(label, value, :encode => "hex")
        else
          sanitize(value)
        end

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
    html_string = "<p>#{t('application_helper.show_comments_for.comment_count',
                          :count => @comments.size)}</p>\n<p>"

    logger.debug("what are comments: " + @comments.inspect)
    if @comments.size > 0
      html_string += t('application_helper.show_comments_for.read_and')
    end

    html_string += link_to(t('application_helper.show_comments_for.join_discussion'),
                           { :action => 'new',
                             :controller => 'comments',
                             :commentable_id => item,
                             :commentable_type => item.class.name,
                             :commentable_private => (item.respond_to?(:private) && item.private?) ? 1 : 0 })

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
        comment_string += "<div class=\"comment-date\">
                            #{t('application_helper.show_comments_for.posted_on')} #{comment.created_at.to_s(:natural)}
                          </div>"

        comment_string += "<ul>"
        comment_string += "<li class='first'>" + link_to(t('application_helper.show_comments_for.reply'),
                                           :controller => 'comments',
                                           :action => :new,
                                           :parent_id => comment) + "</li>\n"

        if logged_in? && @at_least_a_moderator
          comment_string += "<li>" + link_to(t('application_helper.show_comments_for.edit'),
                                             :controller => 'comments',
                                             :action => :edit,
                                             :id => comment) + "</li>\n"
          comment_string += "<li>" + link_to(t('application_helper.show_comments_for.history'),
                                             :controller => 'comments',
                                             :action => :history,
                                             :id => comment) + "</li>\n"
          comment_string += "<li>" + link_to(t('application_helper.show_comments_for.delete'),
                                             {:action => :destroy,
                                               :controller => 'comments',
                                               :id => comment,
                                               :authenticity_token => form_authenticity_token},
                                             :method => :post,
                                             :confirm => t('application_helper.show_comments_for.confirm_delete')) + "</li>\n"
        end

        comment_string += "</ul>\n"
        comment_string += "</div>" # comment-tools
        comment_string += "</div>" # comment-content
        comment_string += "<div class=\"comment-wrapper-footer-wrapper\"><div class=\"comment-wrapper-footer\"></div></div>"
        comment_string += "</div>" # comment-wrapper

        html_string += "<div class='comment-outer-wrapper #{comment_depth_div_classes_for(comment)}'>"
        html_string += stylish_link_to_contributions_of(comment.creators.first, 'Comment',
                                                        :link_text => "<h3>|user_name_link|</h3><div class=\"stylish_user_contribution_link_extra\"><h3>&nbsp;#{t('application_helper.show_comments_for.said')} <a href=\"##{comment.to_anchor}\" name=\"#{comment.to_anchor}\">#{h(comment.title)}</a></h3></div>",
                                                        :additional_html => comment_string)
        html_string += '</div>' # comment-outer-wrapper
      end

      html_string += "<p>" + link_to(t('application_helper.show_comments_for.join_discussion'),
                                     { :action => 'new',
                                       :controller => 'comments',
                                       :commentable_id => item,
                                       :commentable_type => item.class.name,
                                       :commentable_private => (item.respond_to?(:private) && item.private?) ? 1 : 0 }) + "</p>"
    end

    return html_string
  end

  # Calculate the comment depth (how many ancestors)
  # we could call a acts_as_nested_set method here to get ancestor count,
  # but it makes a new query each comment, so try not do that, even if it
  # makes code a little more verbose
  def calculate_comment_depth_for(comment)
    depth, parent_comment_id = 0, comment.parent_id
    until parent_comment_id.blank?
      depth += 1
      parent_comment_id = @comments.select { |c| c.id == parent_comment_id }.first.parent_id rescue nil
    end
    depth
  end

  # Each comment needs to have the classes of it's parent in order of oldest to newest,
  # so if css for a depth of 4 is provided, but css for depth 5 isn't, depth 5 and onward
  # use the last class, in this example, comment-depth-4, for indentation styling instead
  # of having no styling (in which case, they appear as depth 0 which is wrong)
  def comment_depth_div_classes_for(comment)
    classes = Array.new
    0.upto(calculate_comment_depth_for(comment)) do |depth|
      classes << "comment-depth-#{depth}"
    end
    classes.join(' ')
  end

  def flagging_links_for(item, first = false, controller = nil)
    html_string = String.new
    if FLAGGING_TAGS.size > 0 and !item.already_at_blank_version?
      if first
        html_string = "<ul><li class=\"first flag\">#{t('application_helper.flagging_links_for.flag_as')}</li>\n"
      else
        html_string = "<ul><li class=\"flag\">#{t('application_helper.flagging_links_for.flag_as')}</li>\n"
      end
      html_string += "<li class=\"first\"><ul>\n"
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
                                 :confirm => t('application_helper.flagging_links_for.can_you_edit')) + "</li>\n"
        else
          html_string += link_to(flag,
                                 { :action => 'flag_form',
                                   :flag => flag,
                                   :id => item,
                                   :version => item.version },
                                 :confirm => t('application_helper.flagging_links_for.can_you_edit')) + "</li>\n"
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
      html_string = "<h4>#{t('application_helper.pending_review.pending')} "
      privacy_type = item.respond_to?(:private) && item.private? ? "private" : "public"
      if !item.already_at_blank_version?
        html_string += t('application_helper.pending_review.reverted',
                         :privacy_type => privacy_type,
                         :item_version => item.version)
      elsif
        html_string += t('application_helper.pending_review.no_safe_version',
                         :privacy_type => privacy_type)
      end
      html_string += "</h4>"
    end
    return html_string
  end

  def link_to_preview_of(item, version, check_permission = true, options = {})
    # if we got sent a version object, we need to link to the latest version
    item = item.latest_version if item.class.name =~ /Version/

    version_number = 0
    link_text = 'preview'
    begin
      version_number = version.version
    rescue
      link_text = '#' + version
      version_number = version.to_i
    end

    if check_permission == false or can_preview?(:item => item, :version_number => version_number, :submitter => options[:submitter])
      link_to link_text, url_for_preview_of(item, version_number)
    else
      t('application_helper.link_to_preview_of.not_available')
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

  def link_to_original_of(item, phrase=t('application_helper.link_to_original_of.phrase'), skip_warning=false)
    item_file_url = item.is_a?(StillImage) ? item.original_file.public_filename : item.public_filename
    if DOWNLOAD_WARNING.blank? || skip_warning
      link_to phrase, item_file_url
    else
      link_to phrase, item_file_url, :confirm => DOWNLOAD_WARNING
    end
  end

  # we use this in imports, too
  def topic_type_select_with_indent(object, method, collection, value_method, text_method, current_value, html_options=Hash.new, pre_options=Array.new)
    if method
      result = "<select name=\"#{object}[#{method}]\" id=\"#{object}_#{method}\""
    else
      result = "<select name=\"#{object}\" id=\"#{object}\""
    end
    html_options.each do |key, value|
        result << ' ' + key.to_s + '="' + value.to_s + '"'
    end
    result << ">\n"
    result << options_for_select(pre_options) unless pre_options.blank?
    for element in collection
      indent_string = String.new
      element.level.times { indent_string += "&nbsp;" }
      escaped_value = element.send(value_method).to_s.strip.downcase.gsub(/\s/, '_')
      selected = (current_value == escaped_value || current_value.to_i == element.id) ? " selected='selected'" : ''
      result << "<option value='#{escaped_value}'#{selected}>#{indent_string}#{element.send(text_method)}</option>\n"
    end
    result << "</select>\n"
    return result
  end

  def url_for_topics_of_type(topic_type, privacy=nil)
    privacy = 'private' if !params[:private].nil? && params[:private] == "true"

    url_hash = {
      :urlified_name => @site_basket.urlified_name,
      :controller => 'search',
      :controller_name_for_zoom_class => 'topics',
      :topic_type => topic_type.name.downcase.gsub(/\s/, '_'),
      :privacy_type => privacy
    }

    if privacy == 'private'
      basket_all_private_topic_type_path(url_hash)
    else
      basket_all_topic_type_path(url_hash)
    end
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
        theme_styles << web_root_to_file unless stylesheet_for_ie?(web_root_to_file)
      end
    end
    theme_styles
  end

  def stylesheet_for_ie?(stylesheet_path)
    @ie_stylesheet_paths ||= Hash.new
    if stylesheet_path.split('/').last =~ /^ie([0-9]+)/
      @ie_stylesheet_paths[$1.to_i] ||= Array.new
      @ie_stylesheet_paths[$1.to_i] << stylesheet_path
      true
    elsif stylesheet_path.split('/').last =~ /^ie/
      @ie_stylesheet_paths[:all] ||= Array.new
      @ie_stylesheet_paths[:all] << stylesheet_path
      true
    else
      false
    end
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
      direction_image = image_tag('arrow_down.gif', :alt => t('application_helper.search_sorting_controls_for.descending'), :class => 'sorting_control', :width => 16, :height => 7)
    else
      direction == 'asc' # if direction is something else, we set it right here
      direction_image = image_tag('arrow_up.gif', :alt => t('application_helper.search_sorting_controls_for.ascending'), :class => 'sorting_control', :width => 16, :height => 7)
    end

    # create the link based on sort type and direction (user provided or default)
    # keep existing parameters
    location_hash = Hash.new
    # this has keys in strings, rather than symbols
    request.query_parameters.each { |key, value| location_hash[key.to_sym] = value }
    location_hash.merge!({ :order => sort_type })
    location_hash.merge!({ :direction => direction}) if sort_type != 'random'

    # if sorting and the sort is for this sort type, or no sort made and this sort type is the main sort order
    if (params[:order] && params[:order] == sort_type && sort_type != 'random') || (!params[:order] && main_sort_order && sort_type != 'random')
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
      t('application_helper.privacy_image.private')
  end

  def privacy_image_for(item)
    if item.private?
      privacy_image
    end
  end

  def kete_time_ago_in_words(from_time)
    string = String.new
    if from_time < Time.now - 1.week
      string = t('application_helper.kete_time_ago_in_words.longer_than_a_week',
                 :date => from_time.to_s(:euro_date_time))
    else
      string = t('application_helper.kete_time_ago_in_words.within_a_week',
                 :time => time_ago_in_words(from_time))
    end
    string
  end

  # when embedded metadata is set up to be harvested, give an explanation that it is enabled.
  # oriented towards imports at this point, but maybe refined to be generally useful
  def embedded_enabled_message(start_html, end_html)
    html = String.new
    if ENABLE_EMBEDDED_SUPPORT
      html += start_html
      html += t('application_helper.embedded_enabled_message.harvesting')
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

  def categories_field
    @categories ||= ExtendedField.find_by_label('categories')
  end

  def browse_by_category_columns
    # If not, return blank so nothing is displayed
    return '' if categories_field.nil? || !categories_field.is_a_choice?

    # Get the current choice from params (limit_to_choice is special because it also controls search results)
    current_choice = Choice.from_id_or_value(params[:limit_to_choice]) if params[:limit_to_choice]
    parent_choices = Array.new
    unless current_choice.blank?
      # Get all the ancestors and push them onto the parent_choices array
      # reject the ROOT choice (not needed)
      current_choice.self_and_ancestors.reject { |a| a.id == 1 }.each { |a| parent_choices << a }
    end
    # Add the category extended field at the start of the parent_choices array
    parent_choices = [categories_field] + parent_choices

    html = String.new

    # For each level in the parent choices
    parent_choices.size.times do |time|
      # pop the first parent off the end of the parent_choices array
      current_choice = parent_choices.shift

      choices = if current_choice.is_a?(ExtendedField)
        current_choice.choices.find_top_level.reject { |c| !categories_field.choices.member?(c) }
      else
        current_choice.choices.reject { |c| !categories_field.choices.member?(c) }
      end

      # Skip this choice if it doesn't have any choices
      next if choices.size < 1

      html += "<div id='category_level_#{time}' class='category_list'>"
      html += "<ul>"
      # If we're in the first column, provide a link to go back to all results
      html += content_tag('li', link_to(t('application_helper.browse_by_category_columns.all_items',
                                          :item_type => @controller_name_for_zoom_class.gsub(/_/, " ")),
                                        {:view_as => 'choice_hierarchy'}),
                                {:class => (params[:limit_to_choice] ? '' : 'current' )}) if time == 0
      # For every choice in the current choice, lets add a list item
      choices.each do |choice|
        html += list_item_for_choice(choice, { :current => parent_choices.include?(choice), :include_children => false },
                                             { :extended_field => categories_field, :view_as => 'choice_hierarchy' })
      end
      html += '</ul>'
      html += '</div>'
    end

    html += "<div style='clear:both;'></div>"
    #html += javascript_tag("enableCategoryListUpdater('#{params[:controller_name_for_zoom_class]}');")

    html

  end

  def locale_links(options = nil)
    options ||= Hash.new
    options[:default] ||= (current_user != :false ? current_user.locale : I18n.locale)
    choices = ''
    I18n.available_locales_with_labels.each_with_index do |(key,value), index|
      if I18n.locale.to_sym == key.to_sym
        choices << content_tag(:li, value, :class => "current #{'first' if index == 0}")
      else
        choices << content_tag(:li,   link_to(value, {
          :urlified_name => @current_basket.urlified_name,
          :controller => 'account',
          :action => 'change_locale',
          :override_locale => key
        }), :class => ('first' if index == 0))
      end
    end
    content_tag(:ul, choices)
  end

  def locale_dropdown(form=nil, options=nil)
    options ||= Hash.new
    options[:default] ||= if params[:user]
      params[:user][:locale]
    elsif current_user != :false
      current_user.locale
    else
      I18n.locale
    end
    locales = I18n.available_locales_with_labels.collect { |key,value| [value,key] }
    locales = ([[options[:pre_text], '']] + locales) if options[:pre_text]
    if form
      form.select :locale, locales, :selected => options[:default]
    else
      select_tag :override_locale, options_for_select(locales, options[:default])
    end
  end

  def display_search_sources_for(item)
    display_search_sources(item.title, :target => [:all, :items])
  end

  def link_for_rss(options)
    preface = options[:preface]
    title = options[:title]
    link_html = options[:link_html]

    if link_html.scan("combined").any?
      title = t('application_helper.link_for_rss.link_text')
    end

    link_html + preface + ' - ' + title + '</a>'
  end

  # basket preferences helper that is also called in application layout
  # Write tests for this method in Rails 2.3 (which supports helper tests)
  def any_fields_editable?(form_type=@form_type)
    form_type = form_type.to_s
    return true if @site_admin
    return true if @basket.profiles.blank?
    profile_rules = @basket.profiles.first.rules(true)
    return true if profile_rules.blank?
    return true if profile_rules[form_type]['rule_type'] == 'all'
    return false if profile_rules[form_type]['rule_type'] == 'none'
    return false if profile_rules[form_type]['allowed'].blank?
    true
  end

  # determine if we are editing a private version of something
  def adding_or_editing_private_item?
    if @comment
      return params[:commentable_private].param_to_obj_equiv if params[:commentable_private]
      return params[:comment][:commentable_private].param_to_obj_equiv if params[:comment] && params[:comment][:commentable_private]
      return @comment.private?
    else
      if @item_type && params[@item_type] && params[@item_type][:private]
        params[@item_type][:private].param_to_obj_equiv
      elsif @item && !@item.new_record? && !@item.private.nil?
        @item.private?
      elsif @basket
        @basket.private_default_with_inheritance?
      else
        false
      end
    end
  end

end
