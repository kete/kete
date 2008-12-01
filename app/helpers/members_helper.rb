module MembersHelper

  def admin_actions_correct_list_item(user, action_key, action_label, tool_count)
    html_string = String.new
    case action_key
    when 'destroy'
      user_contributions = user.contributions.size
      if user_contributions == 0
        html_string = li_with_correct_class(tool_count) + link_to( action_label, { :action => :destroy, :id => user, :authenticity_token => form_authenticity_token }, :confirm => 'Are you sure?', :method => :post ) + '</li>'
      else
        html_string = li_with_correct_class(tool_count) + user_contributions.to_s + ' contributions</li>'
      end
    when 'ban'
      if !user.banned_at.nil?
        html_string = li_with_correct_class(tool_count) + 'Banned ' + user.banned_at.to_s(:euro_date_time) + link_to( '(undo)', { :action => 'unban', :id => user, :authenticity_token => form_authenticity_token }, :confirm => 'Are you sure?', :method => :post ) + '</li>'
      else
        html_string = li_with_correct_class(tool_count) + link_to( action_label, { :action => action_key, :id => user, :authenticity_token => form_authenticity_token }, :confirm => 'Are you sure?', :method => :post ) + '</li>'
      end
    else
      html_string = li_with_correct_class(tool_count) + link_to( action_label, { :action => action_key, :id => user, :authenticity_token => form_authenticity_token }, :confirm => 'Are you sure?', :method => :post ) + '</li>'
    end
  end

  # override will_paginate's linking, so we can do ajax
  # pretty kludgie and brittle
  # might want to provide a patch to will_paginate instead
  def page_link_or_span(page, span_class = nil, text = page.to_s)
    unless page
      content_tag :span, text, :class => span_class
    else
      # here comes the kludge
      if params[:action] == 'list' or params[:action] == 'index' or params[:action] == 'list_members'
        # :href is a fallback if javascript is disabled
        # page links should preserve most GET parameters, so we merge params
        link_to_remote text, { :update => 'list-members',
          :url => params.merge(:action => 'list_members',
                               :page => (page !=1 ? page : nil)) },
        { :href => url_for(params.merge(:action => 'list', :page => (page !=1 ? page : nil))) }

      else
        # page links should preserve GET parameters, so we merge params
        link_to text, params.merge(:page => (page !=1 ? page : nil))
      end

    end
  end

  def get_user_role_creation_date_for(user, role_type, basket)
    begin
      Role.user_role_for(user, role_type, basket).created_at.to_s(:long)
    rescue
      "unknown"
    end
  end
end
