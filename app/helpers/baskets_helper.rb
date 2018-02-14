# frozen_string_literal: true

module BasketsHelper
  def link_to_link_index_topic(options = {})
    link_to options[:phrase], {
      controller: 'search',
      action: 'find_index',
      current_basket_id: options[:current_basket_id],
      current_homepage_id: options[:current_homepage_id]
    },
            popup: ['links', 'height=500,width=500,scrollbars=yes,top=100,left=100'], tabindex: '1'
  end

  def link_to_add_index_topic(options = {})
    link_to options[:phrase], { controller: 'topics', action: :new, index_for_basket: options[:index_for_basket] }, tabindex: '1'
  end

  def basket_preferences_inheritance_message
    return if @basket != @site_basket # for now, we dont need to tell them,
    # it's obvious with the inherit option
    @inheritance_message = '<p>'
    @inheritance_message += t('baskets_helper.basket_preferences_inheritance_message.inheritance_notice')
    @inheritance_message += '</p>'
  end

  def show_all_fields_link
    html = String.new
    # only show this link if the user is a basket admin
    # and the form hasn't been submitted, and the profile
    # doesn't already show all fields
    if @site_admin && !request.post? &&
       profile_rules && profile_rules[@form_type.to_s] &&
       profile_rules[@form_type.to_s]['rule_type'] != 'all'
      html += '<span class="show_all_fields">['
      action = params[:action] == 'render_basket_form' ? 'new' : params[:action]
      location = { action: action, basket_profile: params[:basket_profile] }
      if params[:show_all_fields]
        html += link_to t('baskets_helper.show_all_fields_link.show_allowed_fields'), location.merge(show_all_fields: nil)
      else
        html += link_to t('baskets_helper.show_all_fields_link.show_all_fields'), location.merge(show_all_fields: true)
      end
      html += ']</span>'
    end
    html
  end
end
